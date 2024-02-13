import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../models/finamp_models.dart';
import '../../services/finamp_settings_helper.dart';

class ContentPlaybackSpeedTypeDropdownListTile extends StatelessWidget {
  const ContentPlaybackSpeedTypeDropdownListTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<FinampSettings>>(
      valueListenable: FinampSettingsHelper.finampSettingsListener,
      builder: (_, box, __) {
        return ListTile(
          title: Text(AppLocalizations.of(context)!.playbackSpeedType),
          subtitle: Text(AppLocalizations.of(context)!.playbackSpeedTypeSubtitle),
          trailing: DropdownButton<ContentPlaybackSpeedType>(
            value: box.get("FinampSettings")?.contentPlaybackSpeedType,
            items: ContentPlaybackSpeedType.values
                .map((e) => DropdownMenuItem<ContentPlaybackSpeedType>(
                      value: e,
                      child: Text(e.toLocalisedString(context)),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                FinampSettingsHelper.setContentPlaybackSpeedType(value);
              }
            },
          ),
        );
      },
    );
  }
}
