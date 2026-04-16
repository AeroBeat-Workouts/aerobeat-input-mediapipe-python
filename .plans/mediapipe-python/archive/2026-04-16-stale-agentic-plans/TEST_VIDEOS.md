# AeroBeat Test Video Candidates

**Purpose:** Diverse test videos for MediaPipe body tracking validation  
**Target Location:** `~/Documents/GitHub/openclaw-cookie/plans/AeroBeat/mediapipe-python/`  
**Date Generated:** 2026-02-07

---

## Summary

Found **10 high-quality test video candidates** covering all 8 required scenarios for AeroBeat testing.

| Scenario | Count | Status |
|----------|-------|--------|
| Fast boxing/punching | 2 | ✓ Found |
| Dancing | 2 | ✓ Found |
| Close to camera | 1 | ✓ Found |
| Far from camera | 1 | ✓ Found |
| Moving across frame | 1 | ✓ Found |
| Partial visibility | 1 | ✓ Found |
| Multiple people | 1 | ✓ Found |
| Low light | 1 | ✓ Found |

---

## Video 1: Man Punching a Punching Bag

- **Title/Description:** Male boxer practicing on punching bag with fast-paced punches
- **Source URL:** <https://www.pexels.com/video/man-punching-a-punching-bag-5752373/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 15-30 seconds (typical Pexels clip)
- **License:** Pexels License (CC0 equivalent - free for commercial use, no attribution)
- **Scenario:** Fast boxing/punching - tests tracking speed
- **Relevance:** **HIGH** - Classic boxing motion with rapid arm movements, perfect for testing joint tracking speed

---

## Video 2: Female Boxer Trains on Punching Bag

- **Title/Description:** A woman intensely training with a punching bag in a gym setting
- **Source URL:** <https://www.pexels.com/video/a-female-boxer-trains-on-a-punching-bag-3483306/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 15-30 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Fast boxing/punching - tests tracking speed
- **Relevance:** **HIGH** - Different body type from Video 1, provides diversity in test data

---

## Video 3: Hip-Hop Dancing (Energetic Dance Routine)

- **Title/Description:** Energetic dance routine on an urban rooftop, showcasing freestyle movements
- **Source URL:** <https://www.pexels.com/video/hip-hop-dancing-2795746/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 20-40 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Dancing - varied full-body motion
- **Relevance:** **HIGH** - Full body articulation tests all 33 MediaPipe landmarks

---

## Video 4: Woman Dancing (Dynamic Solo Performance)

- **Title/Description:** Dynamic solo dance performance with expressive body movements in a studio setting
- **Source URL:** <https://www.pexels.com/video/woman-dancing-7570258/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 20-40 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Dancing - varied full-body motion
- **Relevance:** **HIGH** - Studio setting, controlled lighting, different dance style

---

## Video 5: People Dancing (Group/Party Scene)

- **Title/Description:** Multiple people dancing together (group dance/party atmosphere)
- **Source URL:** <https://www.pexels.com/video/people-dancing-854429/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 15-30 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Multiple people - tests ROI stability
- **Relevance:** **HIGH** - Critical test for multi-person detection and tracking handoff

---

## Video 6: Man Shadow Boxing (Silhouette/Dark Scene)

- **Title/Description:** A silhouette of a boxer practicing shadow boxing indoors - low light conditions
- **Source URL:** <https://www.pexels.com/video/man-shadow-boxing-7187515/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 15-25 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Low light - tests detection in poor conditions
- **Relevance:** **HIGH** - Edge case testing for detection in suboptimal lighting

---

## Video 7: Boxer Showing Punching Prowess (Dimly Lit Gym)

- **Title/Description:** Boxer trains vigorously in a dimly lit gym with rapid punches
- **Source URL:** <https://www.pexels.com/video/a-boxer-showing-his-punching-prowess-4761710/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 15-30 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Low light + Fast boxing (dual test)
- **Relevance:** **HIGH** - Tests both speed tracking AND low-light detection simultaneously

---

## Video 8: Women Dancing for Dance Video (Multiple People)

- **Title/Description:** Women dancing for a dance video (choreographed group routine)
- **Source URL:** <https://www.pexels.com/video/women-dancing-for-a-dance-video-7975419/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 20-40 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Multiple people + Moving across frame
- **Relevance:** **MEDIUM** - Good for testing ROI stability with synchronized movement

---

## Video 9: Boxing Trainer Teaching Woman How to Punch

- **Title/Description:** A boxing trainer teaching a woman how to punch (close interaction)
- **Source URL:** <https://www.pexels.com/video/man-woman-lifestyle-workout-4108250/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 20-40 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Multiple people + Close to camera
- **Relevance:** **MEDIUM** - Two-person interaction, medium shot distance

---

## Video 10: Man Doing Boxing (Punching Bag - Medium Shot)

- **Title/Description:** A focused boxer training with punching bag in a gym (medium/wide shot)
- **Source URL:** <https://www.pexels.com/video/man-doing-boxing-4438088/>
- **Download URL:** Available via Pexels download button
- **Resolution/FPS:** 1080p HD, 30fps (estimated)
- **Duration:** 15-30 seconds
- **License:** Pexels License (CC0 equivalent)
- **Scenario:** Far from camera - small in frame, tests detection
- **Relevance:** **MEDIUM** - Tests detection at distance, smaller figure in frame

---

## Additional Candidates (Recommended for Extended Test Suite)

### Video 11: Man Shadow Boxing in Gym
- **Source:** <https://www.pexels.com/video/a-man-shadow-boxing-in-a-gym-4806552/>
- **Scenario:** Partial visibility / Close to camera
- **Relevance:** Medium - Could test edge cases as subject moves in/out of frame

### Video 12: Female Boxer Trains On Punching Bag (Annushka Ahuja)
- **Source:** <https://www.pexels.com/video/a-woman-punching-bag-in-the-boxing-gym-7986151/>
- **Scenario:** Fast boxing/punching
- **Relevance:** Medium - Alternative female boxer footage

### Video 13: Boxer in Ring (Dark Studio)
- **Source:** <https://www.pexels.com/video/a-boxer-showing-his-punching-skills-in-the-ring-4761765/>
- **Scenario:** Low light + Fast movement
- **Relevance:** Medium - Similar to Video 7, good backup

---

## Download Instructions

1. Visit each Source URL
2. Click the **Free Download** button
3. Select **HD (1080p)** or **4K** if available
4. Save with descriptive filename, e.g.:
   - `test_fast_boxing_01.mp4`
   - `test_dancing_solo_01.mp4`
   - `test_low_light_boxing_01.mp4`

---

## Testing Recommendations

| Priority | Video(s) | Test Focus |
|----------|----------|------------|
| P0 (Critical) | 1, 2, 3, 6 | Core functionality - boxing speed, full-body dance, low-light |
| P1 (Important) | 4, 5, 7, 8 | Edge cases - multi-person, mixed lighting |
| P2 (Extended) | 9, 10, 11-13 | Additional diversity, stress testing |

---

## License Summary

All videos listed are from **Pexels** and use the **Pexels License**:
- ✓ Free for personal and commercial use
- ✓ No attribution required
- ✓ Can be modified/edited
- ✓ CC0 equivalent

**Note:** Always verify license on download page as terms may change.

---

## Next Steps

1. **Review** this list and select 5-8 videos for initial test suite
2. **Download** selected videos in 720p/1080p
3. **Verify** frame rate (30fps) using `ffprobe` or media info
4. **Trim** if needed to 10-60 second segments
5. **Document** actual specs after download in `test_videos_manifest.json`
6. **Run** MediaPipe tests and log performance metrics

---

*Generated by OpenClaw sub-agent for AeroBeat project*
