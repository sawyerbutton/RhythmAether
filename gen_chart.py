import json

lanes = [0.125, 0.375, 0.625, 0.875]
notes = []

def tap(beat, lane_idx):
    notes.append({"type": "tap", "beat": beat, "x": lanes[lane_idx]})

def hold(beat, end_beat, lane_idx):
    notes.append({"type": "hold", "beat": beat, "endBeat": end_beat, "x": lanes[lane_idx]})

def multi_tap(beat, *lane_idxs):
    for l in lane_idxs:
        tap(beat, l)

# Intro (beats 0-7)
tap(0, 1); tap(2, 2); tap(4, 0); tap(5, 1); tap(6, 2); tap(7, 3)

# Building (beats 8-15)
tap(8, 1); tap(8.5, 2); tap(9, 1); tap(9.5, 2)
tap(10, 0); tap(10.5, 1); tap(11, 2); tap(11.5, 3)
multi_tap(12, 0, 3); multi_tap(13, 1, 2)
hold(14, 16, 1); tap(15, 3)

# First groove (beats 16-31)
tap(16, 0); tap(16.5, 1); tap(17, 2); tap(17.5, 3)
tap(18, 2); tap(18.5, 1); tap(19, 0); tap(19.5, 3)
multi_tap(20, 1, 2); multi_tap(21, 0, 3)
tap(22, 1); tap(22.5, 2); tap(23, 1); tap(23.5, 2)
hold(24, 26, 0); tap(25, 2); tap(25.5, 3)
tap(26, 1); tap(26.5, 2); tap(27, 3); tap(27.5, 2)
tap(28, 0); tap(28.5, 1); tap(29, 2); tap(29.5, 3)
tap(30, 2); tap(30.5, 1); multi_tap(31, 0, 3)

# Main (beats 32-47)
multi_tap(32, 0, 1, 2, 3)
tap(33, 1); tap(33.5, 2); tap(34, 1); tap(34.5, 2)
hold(35, 36, 0); tap(35, 3)
tap(36, 1); tap(36.25, 2); tap(36.5, 1); tap(36.75, 2)
tap(37, 0); tap(37.5, 1); tap(38, 2); tap(38.5, 3)
multi_tap(39, 0, 3)
hold(40, 42, 1); hold(40, 42, 2)
tap(42, 0); tap(42.5, 1); tap(43, 2); tap(43.5, 3)
tap(44, 3); tap(44.5, 2); tap(45, 1); tap(45.5, 0)
multi_tap(46, 1, 2); hold(47, 48, 3)

# Main cont (beats 48-63)
tap(48, 0); tap(48.25, 1); tap(48.5, 2); tap(48.75, 3)
tap(49, 2); tap(49.25, 1); tap(49.5, 0); tap(49.75, 1)
tap(50, 2); tap(50.5, 3); tap(51, 2); tap(51.5, 1)
multi_tap(52, 0, 3); multi_tap(53, 1, 2)
hold(54, 56, 0); hold(54, 56, 3)
tap(56, 1); tap(56.5, 2); tap(57, 1); tap(57.5, 2)
tap(58, 0); tap(58.5, 1); tap(59, 2); tap(59.5, 3)
multi_tap(60, 0, 1, 2, 3)
hold(62, 64, 1); hold(62, 64, 2)

# Transition (beats 64-79)
tap(64, 1); tap(66, 2)
tap(68, 0); tap(69, 1); tap(70, 2); tap(71, 3)
tap(72, 1); tap(72.5, 2); tap(73, 1); tap(73.5, 2)
tap(74, 0); tap(75, 3)
hold(76, 78, 1); tap(77, 3); tap(77.5, 2)
tap(78, 0); tap(79, 3)

# Build (beats 80-95)
tap(80, 1); tap(81, 2); tap(82, 1); tap(83, 2)
tap(84, 0); tap(84.5, 1); tap(85, 2); tap(85.5, 3)
tap(86, 2); tap(86.5, 1); tap(87, 0); tap(87.5, 3)
multi_tap(88, 0, 3)
tap(89, 1); tap(89.5, 2); tap(90, 1); tap(90.5, 2)
tap(91, 0); tap(91.5, 1); tap(92, 2); tap(92.5, 3)
multi_tap(93, 1, 2)
hold(94, 96, 0); hold(94, 96, 3)

# Second main (beats 96-127)
multi_tap(96, 0, 1, 2, 3)
tap(97, 1); tap(97.5, 2); tap(98, 3); tap(98.5, 2)
tap(99, 1); tap(99.5, 0)
tap(100, 2); tap(100.5, 3); tap(101, 2); tap(101.5, 1)
hold(102, 104, 0); tap(103, 2); tap(103.5, 3)
tap(104, 1); tap(104.25, 2); tap(104.5, 1); tap(104.75, 2)
tap(105, 0); tap(105.5, 1); tap(106, 2); tap(106.5, 3)
multi_tap(107, 0, 3)
tap(108, 1); tap(108.5, 2); tap(109, 3); tap(109.5, 2)
tap(110, 1); tap(110.5, 0); multi_tap(111, 1, 2)
hold(112, 114, 1); hold(112, 114, 2)
tap(114, 0); tap(114.5, 1); tap(115, 2); tap(115.5, 3)
tap(116, 3); tap(116.5, 2); tap(117, 1); tap(117.5, 0)
multi_tap(118, 0, 3)
tap(119, 1); tap(119.5, 2)
tap(120, 0); tap(120.5, 1); tap(121, 2); tap(121.5, 3)
tap(122, 1); tap(122.5, 2); tap(123, 1); tap(123.5, 2)
multi_tap(124, 0, 3); multi_tap(125, 1, 2)
hold(126, 128, 0); hold(126, 128, 3)

# Peak (beats 128-159)
multi_tap(128, 0, 1, 2, 3)
tap(129, 0); tap(129.5, 1); tap(130, 2); tap(130.5, 3)
tap(131, 2); tap(131.5, 1); tap(132, 0); tap(132.5, 3)
tap(133, 1); tap(133.25, 2); tap(133.5, 1); tap(133.75, 2)
multi_tap(134, 0, 3); hold(135, 136, 1); tap(135.5, 3)
tap(136, 0); tap(136.5, 1); tap(137, 2); tap(137.5, 3)
tap(138, 3); tap(138.5, 2); tap(139, 1); tap(139.5, 0)
multi_tap(140, 1, 2); tap(141, 0); tap(141.5, 3)
tap(142, 1); tap(142.25, 2); tap(142.5, 3); tap(142.75, 2)
tap(143, 1); tap(143.5, 0)
multi_tap(144, 0, 1, 2, 3)
tap(145, 1); tap(145.5, 2); tap(146, 1); tap(146.5, 2)
hold(147, 148, 3); tap(147, 0)
tap(148, 1); tap(148.5, 2); tap(149, 3); tap(149.5, 2)
tap(150, 1); tap(150.5, 0); multi_tap(151, 0, 3)
tap(152, 1); tap(152.25, 2); tap(152.5, 1); tap(152.75, 2)
tap(153, 0); tap(153.5, 3)
hold(154, 156, 1); hold(154, 156, 2)
tap(156, 0); tap(156.5, 1); tap(157, 2); tap(157.5, 3)
multi_tap(158, 0, 3); multi_tap(159, 1, 2)

# Climax (beats 160-191)
multi_tap(160, 0, 1, 2, 3)
tap(161, 0); tap(161.5, 1); tap(162, 2); tap(162.5, 3)
tap(163, 2); tap(163.5, 1); tap(164, 0); tap(164.5, 1)
tap(165, 2); tap(165.5, 3); multi_tap(166, 1, 2)
hold(167, 168, 0); hold(167, 168, 3)
tap(168, 1); tap(168.5, 2); tap(169, 1); tap(169.5, 2)
tap(170, 0); tap(170.5, 1); tap(171, 2); tap(171.5, 3)
multi_tap(172, 0, 3); tap(173, 1); tap(173.5, 2)
tap(174, 3); tap(174.5, 2); tap(175, 1); tap(175.5, 0)
multi_tap(176, 0, 1, 2, 3)
tap(177, 0); tap(177.25, 1); tap(177.5, 2); tap(177.75, 3)
tap(178, 2); tap(178.25, 1); tap(178.5, 0); tap(178.75, 1)
tap(179, 2); tap(179.5, 3)
hold(180, 182, 0); tap(180.5, 2); tap(181, 3); tap(181.5, 2)
tap(182, 1); tap(182.5, 2); tap(183, 1); tap(183.5, 2)
multi_tap(184, 0, 1, 2, 3)
tap(185, 1); tap(185.5, 2); tap(186, 3); tap(186.5, 2)
tap(187, 1); tap(187.5, 0)
hold(188, 190, 1); hold(188, 190, 2)
tap(190, 0); tap(190.5, 3)
multi_tap(191, 0, 1, 2, 3)

# High energy (beats 192-207)
tap(192, 0); tap(192.25, 1); tap(192.5, 2); tap(192.75, 3)
tap(193, 3); tap(193.25, 2); tap(193.5, 1); tap(193.75, 0)
multi_tap(194, 1, 2); tap(195, 0); tap(195.5, 3)
tap(196, 1); tap(196.5, 2); tap(197, 1); tap(197.5, 2)
multi_tap(198, 0, 3)
hold(199, 200, 1); hold(199, 200, 2)
tap(200, 0); tap(200.5, 1); tap(201, 2); tap(201.5, 3)
tap(202, 3); tap(202.5, 2); tap(203, 1); tap(203.5, 0)
multi_tap(204, 0, 1, 2, 3)
hold(206, 208, 1); hold(206, 208, 2)

# Maintain (beats 208-223)
tap(208, 0); tap(208.5, 1); tap(209, 2); tap(209.5, 3)
tap(210, 2); tap(210.5, 1); tap(211, 0); tap(211.5, 3)
multi_tap(212, 1, 2); tap(213, 0); tap(213.5, 3)
hold(214, 216, 0); tap(215, 2); tap(215.5, 3)
tap(216, 1); tap(216.5, 2); tap(217, 1); tap(217.5, 2)
tap(218, 0); tap(218.5, 1); tap(219, 2); tap(219.5, 3)
multi_tap(220, 0, 3)
tap(221, 1); tap(221.5, 2); tap(222, 1); tap(222.5, 2)
multi_tap(223, 0, 1, 2, 3)

# Breakdown (beats 224-239)
tap(224, 1); tap(226, 2)
tap(228, 0); tap(229, 1); tap(230, 2); tap(231, 3)
hold(232, 234, 1)
tap(234, 2); tap(235, 3)
tap(236, 1); tap(236.5, 2); tap(237, 1); tap(237.5, 2)
tap(238, 0); tap(239, 3)

# Rebuild (beats 240-271)
tap(240, 1); tap(241, 2); tap(242, 0); tap(243, 3)
tap(244, 1); tap(244.5, 2); tap(245, 1); tap(245.5, 2)
tap(246, 0); tap(246.5, 1); tap(247, 2); tap(247.5, 3)
multi_tap(248, 0, 3); multi_tap(249, 1, 2)
hold(250, 252, 1); tap(251, 3)
tap(252, 0); tap(252.5, 1); tap(253, 2); tap(253.5, 3)
tap(254, 2); tap(254.5, 1); multi_tap(255, 0, 3)
multi_tap(256, 0, 1, 2, 3)
tap(257, 1); tap(257.5, 2); tap(258, 1); tap(258.5, 2)
tap(259, 0); tap(259.5, 3)
tap(260, 1); tap(260.5, 2); tap(261, 3); tap(261.5, 2)
hold(262, 264, 0); tap(263, 2); tap(263.5, 3)
tap(264, 1); tap(264.5, 2); tap(265, 1); tap(265.5, 2)
multi_tap(266, 0, 3); multi_tap(267, 1, 2)
hold(268, 270, 1); hold(268, 270, 2)
tap(270, 0); tap(270.5, 3)
multi_tap(271, 0, 1, 2, 3)

# Final (beats 272-303)
tap(272, 0); tap(272.5, 1); tap(273, 2); tap(273.5, 3)
tap(274, 2); tap(274.5, 1); tap(275, 0); tap(275.5, 3)
multi_tap(276, 1, 2); tap(277, 0); tap(277.5, 3)
hold(278, 280, 1); hold(278, 280, 2)
tap(280, 0); tap(280.5, 1); tap(281, 2); tap(281.5, 3)
tap(282, 1); tap(282.5, 2); tap(283, 1); tap(283.5, 2)
multi_tap(284, 0, 3)
tap(285, 1); tap(285.5, 2); tap(286, 3); tap(286.5, 2)
tap(287, 1); tap(287.5, 0)
tap(288, 0); tap(289, 1); tap(290, 2); tap(291, 3)
tap(292, 1); tap(293, 2)
hold(294, 296, 1)
tap(296, 2); tap(297, 3)
tap(298, 1); tap(299, 2)

# Outro
multi_tap(300, 1, 2)
hold(302, 306, 1); hold(302, 306, 2)

chart = {
    "version": "1.0.0",
    "metadata": {
        "title": "Think Outside the Box",
        "artist": "Harry Romero & Alex Fioretti",
        "charter": "RhythmAether",
        "audioFile": "../audio/think_outside_the_box.ogg",
        "difficulty": {"label": "Normal", "level": 5}
    },
    "timing": [{"beat": 0, "bpm": 124, "timeSignature": {"numerator": 4, "denominator": 4}}],
    "offset": 1.595,
    "notes": sorted(notes, key=lambda n: n["beat"]),
    "events": []
}

print(f"Total notes: {len(notes)}")
last_end = max((n.get("endBeat", n["beat"]) for n in notes))
print(f"Last beat: {last_end}, covers {last_end * 60/124:.1f}s / 150s")

with open("D:/RhythmAether/resources/charts/think_outside_the_box.json", "w") as f:
    json.dump(chart, f, indent=2)
print("Chart saved!")
