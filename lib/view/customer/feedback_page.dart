import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() =>
      _FeedbackPageState();
}

class _FeedbackPageState
    extends State<FeedbackPage> {

  double rating = 5;
  final TextEditingController feedbackController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const Text(
              'Rate your rental experience',
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,

              label: rating.toString(),

              onChanged: (value) {
                setState(() {
                  rating = value;
                });
              },
            ),

            Text(
              'Rating: ${rating.toInt()} / 5',
            ),

            const SizedBox(height: 20),

            TextField(
              controller: feedbackController,

              maxLines: 4,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Write your feedback...',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Feedback submitted!',
                    ),
                  ),
                );
              },

              child: const Text(
                'Submit Feedback',
              ),
            ),
          ],
        ),
      ),
    );
  }
}