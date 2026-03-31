import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const Map<String, String> privateMessageJsonHeaders = {
  'content-type': 'application/json;charset=UTF-8',
};

Future<Map<String, dynamic>> postPrivateMessageData({
  required http.Client client,
  required Uri url,
  required Map<String, dynamic> body,
  required String requestErrorMessage,
  required String payloadErrorMessage,
}) async {
  final response = await client.post(
    url,
    headers: privateMessageJsonHeaders,
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    throw HttpException(requestErrorMessage);
  }

  final wholeObject = jsonDecode(response.body) as Map<String, dynamic>;
  final data = wholeObject['data'];
  if (data is! Map<String, dynamic>) {
    throw FormatException(payloadErrorMessage);
  }

  return data;
}
