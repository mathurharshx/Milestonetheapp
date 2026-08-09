import { useState, useEffect } from 'react';
import { calculateFullCountdown, CountdownData } from '../utils/dateCalculations';

export function useCountdown(createdAt: Date, targetDate: Date): CountdownData {
  const [countdown, setCountdown] = useState<CountdownData>(
    calculateFullCountdown(createdAt, targetDate)
  );

  useEffect(() => {
    const interval = setInterval(() => {
      setCountdown(calculateFullCountdown(createdAt, targetDate));
    }, 1000);
    return () => clearInterval(interval);
  }, [createdAt, targetDate]);

  return countdown;
}
