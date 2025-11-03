# 🚀 CryptoTracker

Track your cryptocurrency portfolio and watchlist in real time.
Easily add holdings, view live prices, and export or import your data with one tap.

## 📱 Overview

CryptoTracker is a modern iOS app built with SwiftUI, CoreData, and Combine.
It allows users to manage their crypto investments, monitor price changes, and keep their data synced locally.

## ✨ Features

- 📊 Holdings Manager — Add and delete your crypto assets.

- 🪙 Live Price Updates — Fetch real-time crypto prices from the API.

- 📈 Watchlist — Keep track of your favorite coins.

- 💾 Local Persistence — Data stored securely using CoreData.

- 📤 Export / Import — Save or restore holdings via JSON files.

- 💬 Custom Notes — Add personal comments for each holding.

- 🧠 SwiftUI + Combine — Reactive and lightweight architecture.

- ⚙️ Tech Stack

    - Language: Swift

    - Frameworks: SwiftUI, Combine, CoreData

    - Architecture: MVVM

    - API Provider: Freecryptoapi

    - Minimum iOS: 17.0

    - IDE: Xcode 16+

## 🧩 Project Setup

### Clone the repository
```bash
git clone https://github.com/ChrisUBS/MDI1-109-CryptoTracker
```
### Open in Xcode
Open the project folder MDI1-109-CryptoTracker

### Configure API Key
The app requires an API key to fetch crypto prices.
Inside the project, there’s a template file called Info_template.plist.

Steps:

- Duplicate Info_template.plist.

- Rename the copy to Info.plist.

- Open it and replace the placeholder value with your own API key.

Example:
```bash
<key>API_KEY</key>
<string>your_api_key_here</string>
```

### Build & Run
Select your simulator (e.g. iPhone 15 Pro) and press Cmd + R to launch the app.

## 🧠 How It Works

- HoldingsViewModel.swift manages CRUD operations and API calls.

- JSONManager.swift handles exporting/importing holdings via JSON files.

- CoreData is used to persist all user data locally.

- SwiftUI composes all UI elements using reactive bindings (@Published, @StateObject, etc).

## 👨‍💻 Author

- Developed by Christian Bonilla
- Contact: christian.bonilla@uabc.edu.mx