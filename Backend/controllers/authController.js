const User = require("../models/userModel");
const { createSecretToken } = require("../util/SecretToken");
const bcrypt = require("bcryptjs");

module.exports.Signup = async (req, res, next) => {
    try {
        const { email, password, username, createdAt } = req.body;
        //console.log('Received request body:', req.body);

        const existingEmail = await User.findOne({ email });
        const existingUsername = await User.findOne({ username });

        if (existingEmail) {
            return res.json({
                message: "Email already exists",
                success: false,
            });
        }
        if (existingUsername) {
            return res.json({
                message: "Username already exists",
                success: false,
            });
        }

        const user = await User.create({
            email,
            password,
            username,
            createdAt,
        });
        const token = createSecretToken(user._id);
        res.cookie("token", token, {
            path: "/",
            withCredentials: true,
            httpOnly: false,
            secure: process.env.NODE_ENV === "production",
        });
        res.status(201).json({
            message: "User signed up successfully",
            success: true,
            user,
        });
        next();
    } catch (error) {
        console.error(error);
        return res
            .status(500)
            .json({ message: "Internal Server Error", success: false });
    }
};

module.exports.Login = async (req, res, next) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.json({
                message: "All fields are required",
                success: false,
            });
        }
        const user = await User.findOne({ email });
        if (!user) {
            return res.json({
                message: "Incorrect password or email",
                success: false,
            });
        }
        const auth = await bcrypt.compare(password, user.password);
        if (!auth) {
            return res.json({
                message: "Incorrect password or email",
                success: false,
            });
        }
        const token = createSecretToken(user._id);
        res.cookie("token", token, {
            path: "/",
            withCredentials: true,
            httpOnly: false,
            secure: process.env.NODE_ENV === "production",
        });
        res.status(201).json({
            message: "User logged in successfully",
            success: true,
            userDetails: user,
            token: token,
        });
        next();
    } catch (error) {
        console.error(error);
        return res
            .status(500)
            .json({ message: "Internal Server Error", success: false });
    }
};

module.exports.Logout = (req, res, next) => {
    try {
        // clear the token cookie
        res.clearCookie("token", {
            path: "/",
            withCredentials: true,
            httpOnly: false,
            secure: process.env.NODE_ENV === "production",
        });

        //res.cookie('token', '', { expires: new Date(0) });

        res.status(200).json({
            message: "User logged out successfully",
            success: true,
        });

        next();
    } catch (error) {
        console.error(error);
        return res
            .status(500)
            .json({ message: "Internal Server Error", success: false });
    }
};

// TODO
module.exports.deleteAccount = (req, res, next) => {};
