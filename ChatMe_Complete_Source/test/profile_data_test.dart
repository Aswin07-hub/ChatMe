import 'package:flutter_test/flutter_test.dart';
import 'package:chatme/profile_options.dart';

void main() {
  test('profile round-trips through persisted map', () {
    final profile = ProfileData(
      fullName: 'Test User',
      district: 'Chennai',
      occupation: 'Student',
    );

    final restored = ProfileData.fromMap(profile.toMap());

    expect(restored.fullName, 'Test User');
    expect(restored.district, 'Chennai');
    expect(restored.occupation, 'Student');
  });
}
