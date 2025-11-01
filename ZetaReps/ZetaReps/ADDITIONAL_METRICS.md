# Additional Metrics - Future Enhancement Ideas

This document outlines additional metrics that could be valuable for users to track their pushup progress.

## Current Metrics (Implemented)

1. **Consistency Score (0-10)**
   - Frequency (40%): Days worked out vs. expected
   - Current Streak (30%): Consecutive workout days
   - Regularity (30%): How evenly distributed workouts are

2. **Intensity Score (0-10)**
   - Reps/Minute (50%): Average pace during workouts
   - Volume Trend (30%): Improvement over evaluation period
   - Difficulty (20%): Self-rated workout difficulty

## Potential Future Metrics

### 1. Recovery Metrics

**Average Recovery Time**
- Calculate average time between workouts
- Identify optimal rest periods for the user
- Alert if user is overtraining (too frequent) or undertraining (too infrequent)

**Recovery Quality Score**
- Based on performance after rest days vs. consecutive days
- Shows if user performs better with specific rest patterns

### 2. Progress Tracking

**Weekly/Monthly Improvement Rate**
- Week-over-week percentage change in total reps
- Month-over-month trend analysis
- Visual indicator of progress direction (↗️ improving, → plateauing, ↘️ declining)

**Personal Records Dashboard**
- Best single workout (reps)
- Best daily total (if multiple workouts per day)
- Best weekly total
- Best monthly total
- Longest streak
- Most workouts in a week/month

### 3. Performance Analysis

**Time-of-Day Performance**
- Identify when user performs best (morning, afternoon, evening)
- Suggest optimal workout times based on historical data

**Day-of-Week Analysis**
- Which days are strongest/weakest
- Identify patterns (e.g., worse on Mondays, better on Wednesdays)

**Volume Velocity**
- Rate of improvement per week
- Projected milestone dates (e.g., "You'll hit 1000 total reps by...")

### 4. Efficiency Metrics

**Rest Efficiency**
- Total workout duration vs. active rep time
- Identify if user is taking too much or too little rest
- Compare rest patterns to difficulty ratings

**Reps Per Set Average**
- If user logs sets separately, calculate average reps per set
- Track improvement in set quality over time

### 5. Motivation & Behavioral Metrics

**Commitment Score**
- Based on scheduled vs. completed workouts
- Percentage of planned workouts that were actually done
- Identify common times when user skips workouts

**Momentum Score**
- Recent trend (last 7 days) vs. overall trend
- Shows if user is gaining or losing momentum
- Weighted more heavily on recent performance

**Variability Score**
- Consistency of rep counts across workouts
- Lower variability = more predictable performance
- Can indicate stability in training

### 6. Goal-Based Metrics

**Goal Progress Tracker**
- If user sets goals (e.g., "100 pushups in one session")
- Show percentage toward goal
- Estimated date to reach goal based on current trajectory

**Milestone Achievements**
- Track when user hits round numbers (50, 100, 500, 1000 total)
- Celebrate achievements with notifications/badges

### 7. Comparative Metrics

**Personal Best Comparison**
- How current performance compares to all-time bests
- Show as percentage (e.g., "Today's workout was 87% of your best")

**Average Comparison**
- How each workout compares to personal average
- Visual indicator (above/below average)

### 8. Predictive Metrics

**Projected Capacity**
- Based on recent trends, predict maximum reps in next workout
- Suggest when to attempt a new personal record

**Burnout Risk Score**
- Based on frequency, intensity, and declining performance
- Warn user if overtraining patterns are detected

**Plateau Detection**
- Identify when user hasn't improved in X weeks
- Suggest workout variations or rest

## Implementation Priority

### High Priority (Most Value, Easiest to Implement)
1. Personal Records Dashboard
2. Weekly/Monthly Improvement Rate
3. Recovery Time Average
4. Time-of-Day Performance

### Medium Priority
1. Momentum Score
2. Goal Progress Tracker
3. Volume Velocity
4. Day-of-Week Analysis

### Lower Priority (Complex or Niche)
1. Recovery Quality Score
2. Burnout Risk Score
3. Plateau Detection
4. Predictive Metrics

## Technical Considerations

- All metrics should maintain the 30-day evaluation window for consistency
- Metrics requiring historical data should gracefully handle insufficient data
- Complex metrics should have clear, simple explanations in the info view
- Consider computational cost for real-time updates
- Ensure metrics don't overwhelm the UI - perhaps use a "More Metrics" expandable section

## User Experience

- Too many metrics can be overwhelming
- Consider user preferences to show/hide specific metrics
- Use progressive disclosure (basic metrics shown, advanced metrics hidden)
- Provide context and actionable insights, not just numbers
- Celebrate wins and provide constructive guidance on areas for improvement
