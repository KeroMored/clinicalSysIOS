#!/bin/bash

# Replace material_design_icons_flutter icons with Flutter's Icons

TARGET_DIR="/tmp/clinicalSys-github/lib"

echo "🔍 Finding files with MdiIcons..."

# Remove imports
find "$TARGET_DIR" -name "*.dart" -type f -exec sed -i '' \
  "s/import 'package:material_design_icons_flutter\/material_design_icons_flutter.dart';//g" {} \;

# Common icon replacements
find "$TARGET_DIR" -name "*.dart" -type f -exec sed -i '' \
  -e "s/MdiIcons\.whatsapp/Icons.chat/g" \
  -e "s/MdiIcons\.phone/Icons.phone/g" \
  -e "s/MdiIcons\.email/Icons.email/g" \
  -e "s/MdiIcons\.mapMarker/Icons.location_on/g" \
  -e "s/MdiIcons\.map/Icons.map/g" \
  -e "s/MdiIcons\.web/Icons.language/g" \
  -e "s/MdiIcons\.clock/Icons.access_time/g" \
  -e "s/MdiIcons\.calendar/Icons.calendar_today/g" \
  -e "s/MdiIcons\.hospital/Icons.local_hospital/g" \
  -e "s/MdiIcons\.pill/Icons.medication/g" \
  -e "s/MdiIcons\.needle/Icons.healing/g" \
  -e "s/MdiIcons\.stethoscope/Icons.health_and_safety/g" \
  -e "s/MdiIcons\.doctor/Icons.medical_services/g" \
  -e "s/MdiIcons\.ambulance/Icons.local_shipping/g" \
  -e "s/MdiIcons\.heartPulse/Icons.favorite/g" \
  -e "s/MdiIcons\.tooth/Icons.health_and_safety/g" \
  -e "s/MdiIcons\.eye/Icons.visibility/g" \
  -e "s/MdiIcons\.brain/Icons.psychology/g" \
  -e "s/MdiIcons\.dumbbell/Icons.fitness_center/g" \
  -e "s/MdiIcons\.run/Icons.directions_run/g" \
  -e "s/MdiIcons\.yoga/Icons.self_improvement/g" \
  -e "s/MdiIcons\.swim/Icons.pool/g" \
  -e "s/MdiIcons\.walk/Icons.directions_walk/g" \
  -e "s/MdiIcons\.bike/Icons.directions_bike/g" \
  -e "s/MdiIcons\.basketballHoop/Icons.sports_basketball/g" \
  -e "s/MdiIcons\.soccer/Icons.sports_soccer/g" \
  -e "s/MdiIcons\.tennis/Icons.sports_tennis/g" \
  -e "s/MdiIcons\.golf/Icons.golf_course/g" \
  -e "s/MdiIcons\.weightLifter/Icons.fitness_center/g" \
  -e "s/MdiIcons\.medal/Icons.emoji_events/g" \
  -e "s/MdiIcons\.trophy/Icons.emoji_events/g" \
  -e "s/MdiIcons\.home/Icons.home/g" \
  -e "s/MdiIcons\.account/Icons.person/g" \
  -e "s/MdiIcons\.accountCircle/Icons.account_circle/g" \
  -e "s/MdiIcons\.logout/Icons.logout/g" \
  -e "s/MdiIcons\.login/Icons.login/g" \
  -e "s/MdiIcons\.menu/Icons.menu/g" \
  -e "s/MdiIcons\.close/Icons.close/g" \
  -e "s/MdiIcons\.check/Icons.check/g" \
  -e "s/MdiIcons\.delete/Icons.delete/g" \
  -e "s/MdiIcons\.edit/Icons.edit/g" \
  -e "s/MdiIcons\.add/Icons.add/g" \
  -e "s/MdiIcons\.remove/Icons.remove/g" \
  -e "s/MdiIcons\.search/Icons.search/g" \
  -e "s/MdiIcons\.filter/Icons.filter_list/g" \
  -e "s/MdiIcons\.sort/Icons.sort/g" \
  -e "s/MdiIcons\.refresh/Icons.refresh/g" \
  -e "s/MdiIcons\.share/Icons.share/g" \
  -e "s/MdiIcons\.download/Icons.download/g" \
  -e "s/MdiIcons\.upload/Icons.upload/g" \
  -e "s/MdiIcons\.image/Icons.image/g" \
  -e "s/MdiIcons\.camera/Icons.camera_alt/g" \
  -e "s/MdiIcons\.video/Icons.videocam/g" \
  -e "s/MdiIcons\.microphone/Icons.mic/g" \
  -e "s/MdiIcons\.speaker/Icons.volume_up/g" \
  -e "s/MdiIcons\.headphones/Icons.headphones/g" \
  -e "s/MdiIcons\.musicNote/Icons.music_note/g" \
  -e "s/MdiIcons\.playCircle/Icons.play_circle/g" \
  -e "s/MdiIcons\.pauseCircle/Icons.pause_circle/g" \
  -e "s/MdiIcons\.stopCircle/Icons.stop_circle/g" \
  -e "s/MdiIcons\.skipNext/Icons.skip_next/g" \
  -e "s/MdiIcons\.skipPrevious/Icons.skip_previous/g" \
  -e "s/MdiIcons\.fastForward/Icons.fast_forward/g" \
  -e "s/MdiIcons\.rewind/Icons.fast_rewind/g" \
  -e "s/MdiIcons\.volumeHigh/Icons.volume_up/g" \
  -e "s/MdiIcons\.volumeLow/Icons.volume_down/g" \
  -e "s/MdiIcons\.volumeMute/Icons.volume_mute/g" \
  -e "s/MdiIcons\.volumeOff/Icons.volume_off/g" \
  -e "s/MdiIcons\.star/Icons.star/g" \
  -e "s/MdiIcons\.starOutline/Icons.star_border/g" \
  -e "s/MdiIcons\.heart/Icons.favorite/g" \
  -e "s/MdiIcons\.heartOutline/Icons.favorite_border/g" \
  -e "s/MdiIcons\.thumbUp/Icons.thumb_up/g" \
  -e "s/MdiIcons\.thumbDown/Icons.thumb_down/g" \
  -e "s/MdiIcons\.chatProcessing/Icons.chat/g" \
  -e "s/MdiIcons\.comment/Icons.comment/g" \
  -e "s/MdiIcons\.message/Icons.message/g" \
  -e "s/MdiIcons\.send/Icons.send/g" \
  -e "s/MdiIcons\.attachment/Icons.attach_file/g" \
  -e "s/MdiIcons\.paperclip/Icons.attach_file/g" \
  -e "s/MdiIcons\.link/Icons.link/g" \
  -e "s/MdiIcons\.information/Icons.info/g" \
  -e "s/MdiIcons\.informationOutline/Icons.info_outline/g" \
  -e "s/MdiIcons\.alert/Icons.warning/g" \
  -e "s/MdiIcons\.alertCircle/Icons.error/g" \
  -e "s/MdiIcons\.help/Icons.help/g" \
  -e "s/MdiIcons\.helpCircle/Icons.help_outline/g" \
  -e "s/MdiIcons\.settings/Icons.settings/g" \
  -e "s/MdiIcons\.cog/Icons.settings/g" \
  -e "s/MdiIcons\.wrench/Icons.build/g" \
  -e "s/MdiIcons\.hammer/Icons.handyman/g" \
  -e "s/MdiIcons\.screwdriver/Icons.construction/g" \
  -e "s/MdiIcons\.shield/Icons.security/g" \
  -e "s/MdiIcons\.lock/Icons.lock/g" \
  -e "s/MdiIcons\.lockOpen/Icons.lock_open/g" \
  -e "s/MdiIcons\.key/Icons.vpn_key/g" \
  -e "s/MdiIcons\.fingerprint/Icons.fingerprint/g" \
  -e "s/MdiIcons\.faceRecognition/Icons.face/g" \
  {} \;

echo "✅ Icon replacements completed!"
echo "📊 Checking remaining MdiIcons usages..."
grep -r "MdiIcons\." "$TARGET_DIR" --include="*.dart" | wc -l
