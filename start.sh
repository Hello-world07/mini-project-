#!/bin/bash

echo "🔥 Starting Flask Backend..."
cd backend
source venv/bin/activate
python app.py &

echo "🚀 Starting Flutter App..."
cd ..
flutter run -d chrome
