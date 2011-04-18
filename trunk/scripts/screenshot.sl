#
# Screenshot viewer... whee?!?
#
import java.awt.*;
import java.awt.event.*;

import javax.swing.*;
import javax.swing.event.*;
import javax.imageio.*;
import java.io.File;

import armitage.*;

global('%screenshots %webcams');
%screenshots = ohash();
%webcams = ohash();

sub image_viewer
{
	local('$panel $viewer $buttons $refresh $watch');

	$panel = [new JPanel];
	[$panel setLayout: [new BorderLayout]];

		$viewer = [new JLabel];
		[$panel add: [new JScrollPane: $viewer], [BorderLayout CENTER]];

			[$viewer addMouseListener: lambda({
				if ($0 eq "mouseClicked") {
					local('$location');
					$location = saveFile2($sel => "$title $+ _ $+ $sid $+ .jpg");
					if ($location !is $null) {
						[ImageIO write: [[$viewer getIcon] getImage], "jpg", [new File: $location]];
					}
				}
			}, \$viewer, \$title, $sid => $2)];

		$buttons = [new JPanel];
		[$buttons setLayout: [new FlowLayout: [FlowLayout CENTER]]];
			$refresh = [new JButton: "Refresh"];
			[$refresh addActionListener: lambda({
				m_cmd($sid, $command);
			}, $sid => $2, \$command)];
			[$buttons add: $refresh];

			$watch = [new JButton: "Watch (10s)"];
			[$watch addActionListener: lambda({
				local('$timer');
				$timer = [new SimpleTimer: 10000];
				[$timer setRunnable: lambda({
					if ($sid !in $container) {
						[$timer stop];
					}
					else {
						m_cmd($sid, $command);
					}
				}, \$sid, \$timer, \$container, \$command)];
			}, $sid => $2, \$container, \$command)];
			[$buttons add: $watch];
		[$panel add: $buttons, [BorderLayout SOUTH]];
	
	[$frame addTab: "$title $2", $panel, lambda({ $container[$key] = $null; size($container); }, $key => $2, \$container)];
	return $viewer;
}

sub update_viewer {
	if ($0 eq "update" && "*Operation failed*" iswm $2) {
		showError($2);
	}
	else if ($0 eq "update" && $2 ismatch "$type saved to: (.*?)") {
		local('$file $image $panel');
		($file) = matched();

		# we're collaborating, so download the file please...
		if ($client !is $mclient) {
			$file = getFileProper(cwd(), downloadFile($file));
		}

		$image = [ImageIO read: [new File: $file]];

		[$container[$1] setIcon: [new ImageIcon: $image]];

		if (-isFile $file && "*.jpeg" iswm $file) { 
			deleteFile($file);
		}
	}
}

setMissPolicy(%screenshots, { dispatchEvent(lambda(&image_viewer, $title => "Screenshot", $command => "screenshot -v false", $container => %screenshots)); };
setMissPolicy(%webcams, { dispatchEvent(lambda(&image_viewer, $title => "Webcam", $command => "webcam_snap -v false", $container => %webcams)); };

%handlers["screenshot"] = { dispatchEvent(lambda(&update_viewer, $type => "Screenshot", $container => %screenshots)); };
%handlers["webcam_snap"] = { dispatchEvent(lambda(&update_viewer, $type => "Webcam shot", $container => %webcams)); };

sub createScreenshotViewer {
	return lambda({
		m_cmd($sid, "screenshot -v false");
	}, $sid => $1);
}

sub createWebcamViewer {
	return lambda({
		m_cmd($sid, "webcam_snap -v false");
	}, $sid => $1);
}
