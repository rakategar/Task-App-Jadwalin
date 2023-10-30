import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> getProfilePictureURL(String userID) async {
  try {
    final ref = FirebaseStorage.instance.ref().child('profile_pictures/$userID.jpg');
    final url = await ref.getDownloadURL();
    return url;
  } catch (e) {
    print('Error getting profile picture URL: $e');
    return ''; // Atur URL default jika terjadi kesalahan
  }
}
Future<String?> getDisplayName() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.displayName;
    }
    return null;
  } catch (e) {
    print('Error getting display name: $e');
    return null;
  }
}