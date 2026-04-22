require("dotenv").config();
const express = require("express");
const cors = require("cors");
const app = express();
const cloudinary = require("cloudinary").v2;
const fs = require("fs");
const path = require("path");
const multer = require("multer");
const upload_dir = path.join(__dirname, "uploads");
const upload = multer({ dest: upload_dir });
const port = process.env.PORT || 3000;
const mongoose = require('mongoose')

// mongoose.connect("mongodb+srv://luzaMhz:luzaMhz@cluster0.i8dkudl.mongodb.net/?appName=Cluster0").then(() => {
//   console.log('Connected To Database')
// }).catch(err => {
//   console.log('Error Connecting to database')
//   process.exit(1)
// })

!fs.existsSync(upload_dir) ? fs.mkdirSync(upload_dir) : "";

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

app.use(express.json()).use(cors());

app.get("/health", (req, res) =>
  res.status(200).json({
    health: "healthy",
    uptime: process.uptime(),
    method: "get",
  }),
);

app.post("/upload", upload.single("image"), async (req, res) => {
  try {
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: "images-upload",
    });

    // Delete the file from your local 'uploads' folder
    fs.unlinkSync(req.file.path); 

    res.json({
      message: "Upload successfully",
      url: result.secure_url,
    });
  } catch (error) {
    // Also try to cleanup if it fails
    if (req.file) fs.unlinkSync(req.file.path);
    res.status(500).json({ error: "Upload failed" });
  }
});

app.get('/send', (req, res) => {
  const filePath = path.join(__dirname, 'compress.sh');
  res.sendFile(filePath, err => {
    if (err) {
      console.error('Error sending file:', err);
      res.status(500).send('Could not send the file.');
    }
  });
});

app.listen(port, () => {
  console.log("◇ Server listening on http://localhost:" + port);
});
