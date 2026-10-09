# Table Tennis — RULES.md
_Authoritative rules for this game. If the implementation conflicts with this
document, fix the implementation._

## 1. Objective
Outscore your opponent in fast table-tennis rallies. The first player to
reach 11 points with a 2-point lead wins the match.

## 2. Setup
- 2 players: left seat (Player 1) and right seat (Player 2).
- Mode A — Vs Bot: Player 1 is human, Player 2 is the bot (renameable).
- Mode B — Pass-and-play: both seats are human, sharing one phone.
- Bot difficulty: Easy, Medium, Hard (Hard is a PRO feature).
- Player 1 serves the first point of the match.

## 3. Turn order
- Play proceeds point by point; there is no fixed "your turn / my turn"
  beyond the rally flow.
- Each point starts in the SERVE phase with the current server serving.
- The serve launches the ball toward the receiver; the rally then
  alternates between the two seats until someone misses.

## 4. Legal moves
- **Serve:** the server taps Serve (human) or auto-serves after the
  tossing narration (bot). The serve always lands — serves cannot miss.
- **Return:** when the ball travels toward you, TAP anywhere on the table
  within ±200ms of the ball reaching your paddle. Taps within ±90ms are
  *perfect* (smash: faster, flatter return).
- **Spin:** before tapping, swipe UP for topspin (faster return) or DOWN
  for backspin (slower, floatier return). The spin choice applies to the
  next return only and resets after every shot.

## 5. Illegal moves
- Tapping while the ball travels AWAY from you does nothing.
- Tapping twice during one rally: only the first tap counts.
- Tapping during the serve phase, a narration beat, the point
  celebration, or after match end does nothing.
- The bot's seat never accepts taps.

## 6. Captures
None — table tennis has no captures.

## 7. Special rules
- **Early/late swings resolve at arrival:** an early tap locks your swing
  in; if the ball has not arrived within your timing window you whiff.
  There is no penalty beyond losing the point.
- **Narration beats:** every completed return shows a short visible beat
  (callout + AI wind-up narration) before the ball flies back. Input is
  locked during beats.
- **Pause:** pausing freezes the rally mid-flight; resume continues it.

## 8. Scoring
- The player who did NOT miss wins the point (+1).
- Service rotation: the serve swaps every 2 points. At deuce (10–10) the
  serve swaps every 1 point.
- Server for point N (0-based total points played): before deuce,
  `(N / 2) % 2`; at deuce, `N % 2`.

## 9. Winning conditions
- First to 11 points WITH a 2-point lead wins the match immediately.
- There is no point cap: at 10–10 play continues until someone leads by 2.

## 10. Draw conditions
None — every match produces a winner by construction.

## 11. AI strategy
- The bot precomputes its timing error at launch: a Gaussian-ish error
  whose spread shrinks with difficulty and grows with ball speed and spin.
  - Easy: wide spread (~18% miss rate), always lobs slow flat returns.
  - Medium: moderate spread (~5% miss), occasional fast returns.
  - Hard: tight spread (<1% miss), frequent smashes, uses topspin and
    backspin on ~40% of returns.
- The bot's outcome is ALWAYS shown: a visible wind-up animation plus
  narration ("Ace is winding up…", "Ace SMASHES it! 💥"). No silent turns.

## 12. Edge cases
- **App backgrounded mid-rally:** the engine pauses; the rally resumes on
  user resume. Music pauses and resumes via the audio lifecycle.
- **Timer death:** a 3-second watchdog re-arms whichever phase lost its
  timer (rally arrival resolves immediately, AI serve restarts, beats and
  point celebrations advance). No stuck states by construction.
- **Restart mid-rally:** scores, rally counters, and timers reset; the
  opening serve phase restarts with narration.
- **Quit to menu mid-match:** the match is discarded; no stats recorded.

## 13. Test cases
- T1: tap exactly at arrival → return launches; rally counter increments.
- T2: tap 300ms early → whiff; point awarded to opponent with miss callout.
- T3: no tap at all → point awarded to opponent.
- T4: perfect tap (≤90ms) → smash: faster, flatter return + "SMASH! 💥".
- T5: swipe up then perfect tap → fast topspin return; swipe state resets.
- T6: reach 11–9 → match ends immediately with winner banner.
- T7: reach 10–10 → deuce; serve alternates every point; 12–10 wins.
- T8: bot serves → tossing narration → serve launches without any tap.
- T9: bot defends → wind-up animation + narration before every return.
- T10: pause mid-rally → ball freezes; resume → rally continues.
- T11: restart mid-match → scores reset to 0–0, serve phase restarts.
- T12: rename players → names persist across app restarts in order.
- T13: kill the phase timer (simulated) → watchdog recovers within 3s.
