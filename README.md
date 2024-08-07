# 📝 My Notes App
A sleek and intuitive note-taking application created using Flutter and Firebase, now enhanced with AI features powered by Google Gemini!

## ✨ Enhanced Features
- 🔐 Secure user authentication using Firebase Auth
- 💾 Efficient storage and retrieval of notes using Firebase Firestore
- 🌙 Stylish dark mode interface with smooth toggle
- 🔗 Dedicated section for optional links in each note
- 🎨 Improved UI with color-coded notes and card layouts
- 🔍 Advanced search functionality to easily find notes
- 🧠 AI-powered title generator for your notes
- 💬 Chat with your notes using AI assistance
- 🏷️ Tag system for better note organization
- 📌 Pin important notes to the top
- 🗂️ Archive functionality for better note management
- 🗑️ Trash system with auto-deletion after 30 days
- 📊 Staggered grid view for dynamic note display
- 🖌️ Color filter for easy note browsing
- 📱 Responsive design for various screen sizes
- 🔑 Reset PIN feature for locked notes
- 🔄 Automatic app update checks using Firebase Remote Config

## 🔐 Security Features
- **Locked Notes**: Secure your sensitive notes with a 4-digit PIN
- **PIN Reset**: Easily reset your PIN if forgotten, with email verification for added security
- **Auto-lock**: Locked notes are automatically hidden from the main view

## 🔄 App Updates
- Now you can check for updates using Firebase Remote Config
- Seamless update process with in-app prompts
- Ensures users always have the latest features and security improvements
- You can get the latest version from the GitHub repository

## 🤖 AI Features
- **AI Title Generator**: Automatically generate catchy and relevant titles for your notes using Google Gemini AI
- **Chat with Notes**: Engage in a conversation about your notes with an AI assistant, powered by Google Gemini
- **AI-Powered Note Manipulation**: Use special commands to modify your notes with AI assistance

### New AI Commands
Our app now includes powerful AI-driven commands to help you manipulate and enhance your notes:

- **/edit**: Allows you to make specific edits to your note content using natural language instructions.
  Example: "/edit Change the second paragraph to focus more on the benefits of exercise"

- **/update**: Similar to /edit, but typically used for broader updates or additions to your note.
  Example: "/update Add a section about the importance of staying hydrated during workouts"

- **/rewrite**: Completely rewrites your note while maintaining the core message, useful for improving clarity or changing the tone.
  Example: "/rewrite Make this note more formal and suitable for a professional report"

- **/addemoji**: Enhances your note by adding relevant emojis to key points or sections.
  Example: "/addemoji Add appropriate emojis to make this shopping list more visually appealing"

- **/translate**: Translates your note content into a specified language.
  Example: "/translate Convert this note to Spanish"

To use these commands, simply type them at the beginning of your message in the chat interface, followed by your specific instruction. The AI will process your request and provide the modified note content, which you can then review, edit further, or confirm to update your original note.

## 🌈 Color Coding
- Easily categorize and visually organize your notes with a selection of colors
- Choose from a range of preset colors when creating or editing a note
- Quickly identify note categories at a glance in the main notes list
- Filter notes by color for efficient organization

## 📋 Note Management
- **Archive**: Move less frequently used notes to the archive for a cleaner main view
- **Trash**: Safely delete notes with the ability to restore them within 30 days
- **Auto-deletion**: Notes in the trash are automatically deleted after 30 days

## 📸 Screenshots
![Main image](https://github.com/user-attachments/assets/f445b58c-2fb3-4cd2-81bf-fa076af234c2)

## 🛠️ Technologies Used
- 📱 Flutter for cross-platform development
- 🔑 Firebase Authentication for secure user management
- 🗄️ Firebase Firestore for real-time data storage
- 🔄 Firebase Remote Config for dynamic app updates
- 🤖 Google Gemini for AI-powered features
- 📊 flutter_staggered_grid_view for dynamic note layouts
- 🎭 animated_text_kit for engaging text animations
- 🔗 url_launcher for opening links within notes
- 📤 share_plus for sharing note content
- 💾 shared_preferences for local data storage
- 🎨 flutter_colorpicker for color selection

## 🚀 Getting Started
1. 📥 Clone the repository
2. 📦 Install dependencies using `flutter pub get`
3. 🔧 Set up Firebase
   - Create a new Firebase project
   - Add your Flutter app to the Firebase project
   - Download and add the configuration files to the appropriate directory
   - Enable Authentication and Firestore in your Firebase console
   - Set up Remote Config for app updates
4. 🤖 Set up Google Gemini
   - Obtain an API key for Google Gemini
   - Add the API key to your `key.dart` file (ensure it's kept secure and not exposed in public repositories)
5. ▶️ Run the app using `flutter run`

## 📖 Usage
- 👤 Register or login with a sleek, user-friendly interface
- ➕ Tap the floating action button to add a new note
- ✏️ Fill in the title, content, and an optional link for your note
- 🧠 Use the AI title generator to create a title based on your note content
- 🎨 Select a color for your note to categorize it
- 🏷️ Add tags to your notes for easy filtering
- 📌 Pin important notes to keep them at the top of your list
- 💾 Tap 'Save Note' to store your note
- 🔍 Use the search functionality in the app bar to find specific notes
- 💬 Chat with your notes to get AI-powered insights and answers
- 🤖 Use AI commands (/edit, /update, /rewrite, /addemoji, /translate) to manipulate your notes
- 🌓 Toggle between light and dark modes for comfortable viewing
- 🗂️ Archive notes you don't need frequently
- 🗑️ Move notes to trash and restore them if needed
- 🎨 Use color filters to browse notes by category
- 🔐 Set a PIN to lock sensitive notes
- 🔑 Reset your PIN if forgotten, using email verification
- 🔄 Receive prompts for app updates when available

## 🆕 UI Enhancements
- Color-coded notes for easy visual categorization
- Card-based layout for better organization
- Staggered grid view for dynamic note display
- Animated text effects for engaging user experience
- Responsive design for various screen sizes
- Customizable color filters for note browsing
- Drawer menu for easy navigation between notes, archive, and trash

## 🤝 Contributing
Contributions, issues, and feature requests are welcome. Feel free to check [issues page](https://github.com/YourUsername/my_notes_app/issues) if you want to contribute.

## 👨‍💻 Author
Piyush Bhardwaj

## 🙏 Acknowledgements
- Flutter framework
- Firebase platform
- Google Gemini AI
- flutter_staggered_grid_view package
- animated_text_kit package
- url_launcher package
- share_plus package
- intl package for date formatting
- shared_preferences package
- flutter_colorpicker package