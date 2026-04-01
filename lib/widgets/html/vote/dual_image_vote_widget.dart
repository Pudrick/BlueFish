import 'package:bluefish/models/vote.dart';
import 'package:bluefish/widgets/html/vote/vote_info_widget.dart';
import 'package:flutter/material.dart';

class DualImageVoteWidget extends StatelessWidget {
  final Vote vote;

  static const double outerBorderRoundRadius = 12;
  static const double innerBorderRoundRadius = 10;
  static const double buttonVerticalMargin = 24;

  DualImageVoteWidget({super.key, required this.vote})
    : assert(vote.isDualImageLayout);

  VoteOption get _leftOption => vote.options[0];

  VoteOption get _rightOption => vote.options[1];

  bool get _leftSelected => vote.isOptionSelected(_leftOption.sort);

  bool get _rightSelected => vote.isOptionSelected(_rightOption.sort);

  int _resolvedFlex(int value) => value > 0 ? value : 1;

  Widget _canVoteButtonWidget() {
    const double buttonVerticalMargin = 25;
    const double buttonTextSize = 27;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: buttonVerticalMargin,
              ),
              backgroundColor: Colors.redAccent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(DualImageVoteWidget.outerBorderRoundRadius),
                ),
              ),
            ),
            child: Text(
              _leftOption.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: buttonTextSize,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: buttonVerticalMargin,
              ),
              backgroundColor: Colors.blue,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(DualImageVoteWidget.outerBorderRoundRadius),
                ),
              ),
            ),
            child: Text(
              _rightOption.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: buttonTextSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cannotVoteButtonWidget(BuildContext context) {
    const double buttonTextSize = 17;
    const double buttonHeight = 70;
    final leftColorOfNumberVotes = Theme.of(
      context,
    ).colorScheme.onTertiaryContainer;
    final rightColorOfNumberVotes = Theme.of(
      context,
    ).colorScheme.onSecondaryContainer;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: buttonHeight,
          child: Row(
            children: [
              Card(
                elevation: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        DualImageVoteWidget.outerBorderRoundRadius,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_leftOption.percentage * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: leftColorOfNumberVotes,
                            fontSize: 20,
                          ),
                        ),
                        Column(
                          children: [
                            if (_leftSelected)
                              Icon(Icons.check, color: leftColorOfNumberVotes),
                            const SizedBox(width: 5),
                            Text(
                              _leftOption.optionVoteCount.toString(),
                              style: TextStyle(
                                color: leftColorOfNumberVotes,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: _resolvedFlex(_leftOption.optionVoteCount),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        DualImageVoteWidget.outerBorderRoundRadius,
                      ),
                    ),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: _resolvedFlex(_rightOption.optionVoteCount),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        DualImageVoteWidget.outerBorderRoundRadius,
                      ),
                    ),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Card(
                elevation: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        DualImageVoteWidget.outerBorderRoundRadius,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_rightOption.percentage * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: rightColorOfNumberVotes,
                            fontSize: 20,
                          ),
                        ),
                        Row(
                          children: [
                            if (_rightSelected)
                              Icon(
                                Icons.check_circle,
                                color: rightColorOfNumberVotes,
                              ),
                            const SizedBox(width: 5),
                            Text(
                              _rightOption.optionVoteCount.toString(),
                              style: TextStyle(
                                color: rightColorOfNumberVotes,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: DualImageVoteWidget.buttonVerticalMargin,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        DualImageVoteWidget.outerBorderRoundRadius,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_leftSelected)
                      Icon(
                        Icons.check,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.38),
                        size: buttonTextSize,
                      ),
                    Text(
                      _leftOption.content,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.38),
                        fontSize: buttonTextSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 7),
            if (vote.canCancelVote)
              SizedBox(
                height: 55,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                          DualImageVoteWidget.innerBorderRoundRadius,
                        ),
                      ),
                    ),
                  ),
                  child: const Text(
                    '取消投票',
                    style: TextStyle(fontSize: buttonTextSize),
                  ),
                ),
              ),
            if (vote.canCancelVote) const SizedBox(width: 7),
            Expanded(
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: DualImageVoteWidget.buttonVerticalMargin,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        DualImageVoteWidget.outerBorderRoundRadius,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_rightSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.38),
                        size: buttonTextSize,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _rightOption.content,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.38),
                        fontSize: buttonTextSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _voteImageWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 1,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(DualImageVoteWidget.outerBorderRoundRadius),
            ),
            child: Image.network(
              _leftOption.attachment.toString(),
              fit: BoxFit.fill,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(DualImageVoteWidget.outerBorderRoundRadius),
            ),
            child: Image.network(
              _rightOption.attachment.toString(),
              fit: BoxFit.fill,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          children: [
            VoteInfoWidget(vote: vote),
            const SizedBox(height: 10),
            _voteImageWidget(),
            const SizedBox(height: 10),
            if (vote.canVote)
              _canVoteButtonWidget()
            else
              _cannotVoteButtonWidget(context),
          ],
        ),
      ),
    );
  }
}
