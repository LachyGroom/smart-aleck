# Smart aleck

Smart aleck flashes and plays an alert sound any time you type the word "just". 

## Getting Started

### Prerequisites

- macOS 10.15 or later.
- Xcode 11 or later.

### Installation

1. Clone the repository to your local machine:

   ```
   git clone https://github.com/lachygroom/smart-aleck.git
   ```

2. Open the project in Xcode:

   ```
   open JustDetector.xcodeproj
   ```

3. Build and run the application:

   - Select the target in Xcode and run it on your Mac.

### Granting Permissions

For the application to monitor keystrokes across all applications, you must grant it Accessibility permissions:

1. Open System Preferences.
2. Go to Security & Privacy > Privacy > Accessibility.
3. Click the lock icon to make changes (you may need to enter your administrator password).
4. Find the application in the list and check the box to grant permissions.
5. Restart the application for the changes to take effect.

## Usage

Once running, the application will:

- Monitor for the specified keystroke ("just") across all applications.
- Log each occurrence with the surrounding context to a database.
- Update the keystroke count displayed in the menu bar in real-time.
