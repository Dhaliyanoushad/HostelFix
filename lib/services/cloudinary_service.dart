import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = "ddoyfgzip";
  final String uploadPreset = "hostel_upload";

  Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      return jsonData['secure_url'];
    } else {
      return null;
    }
  }
}
