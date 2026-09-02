import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

// Enhancement 3:
// single source of truth for the demo user id
const int demoUserId = 8;