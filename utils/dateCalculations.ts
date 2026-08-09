export interface CountdownData {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
  totalDays: number;
  daysElapsed: number;
  daysRemaining: number;
  totalHours: number;
  hoursElapsed: number;
  /** true when total mission duration is under 24 hours */
  isUnder24h: boolean;
  progressPercent: number;
  isExpired: boolean;
}

function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function differenceInDays(dateA: Date, dateB: Date): number {
  const a = startOfDay(dateA);
  const b = startOfDay(dateB);
  return Math.round((a.getTime() - b.getTime()) / (1000 * 60 * 60 * 24));
}

export function getDaysRemaining(targetDate: Date): number {
  const now = startOfDay(new Date());
  const target = startOfDay(targetDate);
  return Math.max(0, differenceInDays(target, now));
}

export function getDaysElapsed(createdAt: Date): number {
  const now = startOfDay(new Date());
  const created = startOfDay(createdAt);
  return Math.max(0, differenceInDays(now, created));
}

export function getTotalDays(createdAt: Date, targetDate: Date): number {
  const created = startOfDay(createdAt);
  const target = startOfDay(targetDate);
  return Math.max(1, differenceInDays(target, created));
}

export function calculateCountdown(targetDate: Date): CountdownData {
  const now = new Date();
  const target = new Date(targetDate);
  const diff = target.getTime() - now.getTime();

  const totalDays = 1;
  const daysElapsed = 0;
  const daysRemaining = getDaysRemaining(targetDate);

  if (diff <= 0) {
    return {
      days: 0,
      hours: 0,
      minutes: 0,
      seconds: 0,
      totalDays,
      daysElapsed,
      daysRemaining: 0,
      totalHours: 0,
      hoursElapsed: 0,
      isUnder24h: false,
      progressPercent: 100,
      isExpired: true,
    };
  }

  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);

  return {
    days,
    hours,
    minutes,
    seconds,
    totalDays,
    daysElapsed,
    daysRemaining,
    totalHours: 0,
    hoursElapsed: 0,
    isUnder24h: false,
    progressPercent: 0,
    isExpired: false,
  };
}

export function calculateFullCountdown(
  createdAt: Date,
  targetDate: Date
): CountdownData {
  const now = new Date();
  const target = new Date(targetDate);
  const created = new Date(createdAt);
  const diff = target.getTime() - now.getTime();

  const totalDays = getTotalDays(createdAt, targetDate);
  const daysElapsed = getDaysElapsed(createdAt);
  const daysRemaining = getDaysRemaining(targetDate);
  const progressPercent =
    totalDays > 0 ? Math.min(100, Math.round((daysElapsed / totalDays) * 100)) : 0;

  // Hour-based calculations for missions under 24 hours
  const totalMs = target.getTime() - created.getTime();
  const elapsedMs = now.getTime() - created.getTime();
  const totalHours = Math.max(1, Math.ceil(totalMs / (1000 * 60 * 60)));
  const hoursElapsed = Math.max(0, Math.min(totalHours, Math.floor(elapsedMs / (1000 * 60 * 60))));
  const isUnder24h = totalMs < 24 * 60 * 60 * 1000;

  if (diff <= 0) {
    return {
      days: 0,
      hours: 0,
      minutes: 0,
      seconds: 0,
      totalDays,
      daysElapsed,
      daysRemaining: 0,
      totalHours,
      hoursElapsed: totalHours,
      isUnder24h,
      progressPercent: 100,
      isExpired: true,
    };
  }

  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);

  return {
    days,
    hours,
    minutes,
    seconds,
    totalDays,
    daysElapsed,
    daysRemaining,
    totalHours,
    hoursElapsed,
    isUnder24h,
    progressPercent,
    isExpired: false,
  };
}

export function formatDate(date: Date): string {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`;
}

export function formatDuration(startDate: Date, endDate: Date): string {
  const days = differenceInDays(endDate, startDate);
  if (days < 7) return `${days} day${days !== 1 ? 's' : ''}`;
  if (days < 30) {
    const weeks = Math.floor(days / 7);
    return `${weeks} week${weeks !== 1 ? 's' : ''}`;
  }
  const months = Math.floor(days / 30);
  return `${months} month${months !== 1 ? 's' : ''}`;
}
