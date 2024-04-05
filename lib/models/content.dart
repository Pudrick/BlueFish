abstract class Content {}

class TextContent implements Content {
  late String content;
}

class ImageContent implements Content {
  late Uri imageURL;

  ImageContent(String URL) {
    imageURL = Uri.parse(URL);
  }
}
