# Network Image Cache

Network image with cache technology.

## Installation

Add this to your package's `pubspec.yaml` file and then run `pub get`:

```yaml
dependencies:
  network_image_cache: 
    git: https://github.com/ArZHa03/network_image_cache.git
```

## Usage

To use this package, import it and use the NetworkImageCache widget:

```dart
import 'package:network_image_cache/network_image_cache.dart';
```

```dart
NetworkImageCache(
  url: 'https://avatars.githubusercontent.com/u/106745041?v=4',
  width: 100,
  height: 100,
  fadeInDuration: Duration(milliseconds: 300),
);
```

## Example

Here is a complete example:

```dart
import 'package:flutter/material.dart';
import 'package:network_image_cache/network_image_cache.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Network Image Cache Example')),
        body: Center(
          child: NetworkImageCache(
            url: 'https://avatars.githubusercontent.com/u/106745041?v=4',
            width: 100,
            height: 100,
            fadeInDuration: Duration(milliseconds: 300),
          ),
        ),
      ),
    );
  }
}
```

## API

### NetworkImageCache

| Property | Description | Type | Default |
| --- | --- | --- | --- |
| url | The URL from which the image will be fetched. | String | |
| width | The width of the image. | double | |
| height | The height of the image. | double | |
| fadeInDuration | The duration of the fade-in animation. | Duration | Duration(milliseconds: 300) |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.