import 'package:flutter_dotenv/flutter_dotenv.dart';

String projectURI = dotenv.env['PROJECT_URI'] ?? '';

String anonKey = dotenv.env['ANON_KEY'] ?? '';
