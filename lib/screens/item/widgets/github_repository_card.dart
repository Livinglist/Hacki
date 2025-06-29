import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/github/github_cubit.dart';
import 'package:hacki/cubits/github/github_states.dart';

class GithubRepositoryCard extends StatelessWidget {
  const GithubRepositoryCard({
    required this.url,
    super.key,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GithubCubit, GithubState>(
      builder: (context, state) {
        final repository = state.repositories[url];

        if (repository == null) {
          if (state.status == GithubStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    repository.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(repository.description),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.star_border_sharp),
                      const SizedBox(width: 5),
                      Text('${repository.stars} Stars'),
                      const Spacer(),
                      const Icon(Icons.file_copy_sharp),
                      const SizedBox(width: 5),
                      Text(repository.license),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.remove_red_eye_sharp),
                      const SizedBox(width: 5),
                      Text('${repository.watching} watching'),
                      const Spacer(),
                      const Icon(Icons.code),
                      const SizedBox(width: 5),
                      Text(repository.language),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.fork_right_sharp),
                      const SizedBox(width: 5),
                      Text('${repository.forks} forks'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
