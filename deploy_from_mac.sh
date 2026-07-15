#!/bin/bash

echo "🍎 Installing Node.js and Firebase CLI on Mac..."
echo "================================================"
echo ""

# Step 1: Install Node.js
echo "1️⃣ Installing Node.js via Homebrew..."
brew install node

echo ""
echo "✅ Node.js installed!"
node --version
npm --version
echo ""

# Step 2: Install Firebase CLI
echo "2️⃣ Installing Firebase CLI..."
npm install -g firebase-tools

echo ""
echo "✅ Firebase CLI installed!"
firebase --version
echo ""

# Step 3: Login to Firebase
echo "3️⃣ Logging in to Firebase..."
echo "   (Browser will open - login with kerolesmored@gmail.com)"
firebase login

echo ""

# Step 4: Set project
echo "4️⃣ Setting Firebase project..."
firebase use clinicalsystem-4da35

echo ""

# Step 5: Deploy functions
echo "5️⃣ Deploying Cloud Functions..."
echo "   ⏱ This will take 5-10 minutes..."
firebase deploy --only functions

echo ""
echo "================================================"
echo "✅ DEPLOY COMPLETE!"
echo "================================================"
echo ""
echo "Checking deployed functions..."
firebase functions:list

echo ""
echo "🎉 Push Notifications are now LIVE!"
echo ""
echo "Test by:"
echo "1. Making an online clinic booking"
echo "2. Creating a pharmacy offer"
echo "3. Requesting medicine"
echo ""
