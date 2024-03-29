const LikedContent = require("../models/likedContentModel");
const FollowedUsers = require("../models/followedUsersModel");

// In order for a user to get recommendation from a followedUser
// trackNum is the number of track recommendations
/*
    params: {
        trackNum: integer
    }
*/

module.exports.recommendTrackFromFollowedUser = async (req, res) => {
    try {
        // Get user information from the information coming from verifyToken middleware
        const user = req.user;
        const { username } = user;

        // Get users likedTracks
        const likedContent = await LikedContent.findOne({ username })
            .populate({
                path: "likedTracks.track",
                populate: {
                    path: "artists",
                    select: "genres",
                },
            })
            .lean();

        // If user does not have a likedContent, throw error
        if (
            !likedContent ||
            !likedContent.likedTracks ||
            likedContent.likedTracks.length === 0
        ) {
            return res.json({
                message:
                    "No liked tracks found for the user or user doesn't exist.",
                success: false,
            });
        }

        const genreCount = {};

        for (const trackObj of likedContent.likedTracks) {
            const artists = trackObj.track.artists;

            if (!artists || !Array.isArray(artists) || artists.length === 0) {
                console.log("No artists or empty artists array found:", song);
                continue; // Skip this track if there are no artists or if artists is not an array
            }

            //Get genres from artists of tracks
            for (const artist of artists) {
                if (
                    artist.genres &&
                    Array.isArray(artist.genres) &&
                    artist.genres.length > 0
                ) {
                    for (const genre of artist.genres) {
                        genreCount[genre] = (genreCount[genre] || 0) + 1;
                    }
                }
            }
        }

        //If users likedTracks have no genre, throw error
        if (Object.keys(genreCount).length === 0) {
            return res.json({
                message: "No genres found in the liked songs.",
                success: false,
            });
        }

        const mostCommonGenre = Object.keys(genreCount).reduce((a, b) =>
            genreCount[a] > genreCount[b] ? a : b
        );

        const currentUser = await FollowedUsers.findOne({ username });

        //Create and edit a list of users that meets the requirements
        let randomFollowedUser;
        if (currentUser) {
            const duplicateFollowedUsersList = [
                ...currentUser.followedUsersList,
            ];

            for (
                let index = 0;
                index < duplicateFollowedUsersList.length;
                index++
            ) {
                const currentFollowedUsername =
                    duplicateFollowedUsersList[index];

                // Find the document for the current followed user
                const currentFollowedUserSchema = await FollowedUsers.findOne({
                    username: currentFollowedUsername,
                });
                const currentFollowedUserLikedContent =
                    await LikedContent.findOne({
                        username: currentFollowedUsername,
                    });

                if (currentFollowedUserSchema) {
                    const currentFollowedUsersBlockList =
                        currentFollowedUserSchema.recommendationBlockedUsersList;
                    const currentFollowedUsersLikedTracks =
                        currentFollowedUserLikedContent.likedTracks;

                    if (
                        currentFollowedUsersBlockList &&
                        currentFollowedUsersBlockList.indexOf(username) !== -1
                    ) {
                        // Delete the followedUser that blocked the user
                        duplicateFollowedUsersList.splice(index, 1);
                        index--;
                    } else if (currentFollowedUsersLikedTracks.length == 0) {
                        //Delete the followedUser if their likedTracks are empty
                        duplicateFollowedUsersList.splice(index, 1);
                        index--;
                    }
                }
            }

            //Choose a user from created list
            if (duplicateFollowedUsersList.length > 0) {
                const randomIndex = Math.floor(
                    Math.random() * duplicateFollowedUsersList.length
                );
                randomFollowedUser = duplicateFollowedUsersList[randomIndex];
            } else {
                return {
                    success: false,
                    message: "The followed users list is empty.",
                    user,
                };
            }
        } else {
            return { success: false, message: "User not found." };
        }

        // Function to find tracks by genre from a user's liked songs
        async function findTracksByGenre(
            username,
            followedUsername,
            genre,
            trackNum
        ) {
            try {
                // Find the followed user's liked songs list
                const followedLikedContentFirst = await LikedContent.findOne({
                    username: followedUsername,
                });
                const followedLikedContent = await followedLikedContentFirst
                    .populate({
                        path: "likedTracks.track",
                        populate: {
                            path: "artists",
                            select: ["genres", "name", "imageURL"],
                        },
                    })
                    .then((populated) => {
                        return populated.populate("likedTracks.track.album", [
                            "name",
                            "imageURL",
                        ]);
                    });

                const likedContent = await LikedContent.findOne({ username });

                // Filter tracks by the specified genre
                const tracksWithGenre = followedLikedContent.likedTracks.filter(
                    (trackList) =>
                        trackList.track.artists.some((artist) =>
                            artist.genres.includes(genre)
                        )
                );

                const existingTrackIds = likedContent.likedTracks.map(
                    (trackList) => trackList.track._id
                );

                //Delete track from recommendation if the recommended track is in users likedSongsList,
                const filteredTracks = tracksWithGenre.filter(
                    (track) => !existingTrackIds.includes(track._id)
                );

                filteredTracks.filter(
                    (value, index, self) => self.indexOf(value) === index
                ); //Delete duplicate tracks
                filteredTracks.sort(() => Math.random() - 0.5); // Shuffle array

                // Return up to 'trackNum' tracks matching the genre
                return filteredTracks.slice(0, trackNum);
            } catch (error) {
                console.error("Error finding tracks by genre:", error);
                return [];
            }
        }

        // Get trackNum
        const { trackNum } = req.params;
        const recommendations = await findTracksByGenre(
            username,
            randomFollowedUser,
            mostCommonGenre,
            trackNum
        );

        res.status(201).json({
            message: `These tracks are recommended from user: ${randomFollowedUser}`,
            recommendations,
            success: true,
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};
