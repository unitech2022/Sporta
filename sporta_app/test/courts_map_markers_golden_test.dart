// Renders the padel-ball marker to a golden image so its custom painting can be
// checked without launching the app.
//
// Run:  flutter test --update-goldens test/courts_map_markers_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/features/courts/presentation/widgets/courts/courts_map_view.dart';

void main() {
  testWidgets('padel ball marker renders at marker and zoomed sizes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          // Stand-in for the map tiles underneath.
          backgroundColor: Color(0xFFBFD8BD),
          body: Center(
            child: RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Actual size on the map.
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CustomPaint(painter: CourtBallPainter()),
                    ),
                    SizedBox(width: 24),
                    // Blown up so the seams are inspectable.
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(painter: CourtBallPainter()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/courts_ball_marker.png'),
    );
  });
}
