interface ProgressRingProps {
  size?: number;
  strokeWidth?: number;
  progress: number; // 0 to 100
  colorClass?: string;
}

export default function ProgressRing({ size = 120, strokeWidth = 10, progress, colorClass = 'stroke-white' }: ProgressRingProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const strokeDashoffset = circumference - (Math.min(Math.max(progress, 0), 100) / 100) * circumference;

  return (
    <div className="relative flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="transform -rotate-90">
        {/* Track circle */}
        <circle
          className="stroke-dark-border"
          fill="transparent"
          strokeWidth={strokeWidth}
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
        {/* Animated Progress circle */}
        <circle
          className={`${colorClass} transition-all duration-500 ease-out`}
          fill="transparent"
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
      </svg>
      {/* Percentage Center Text */}
      <div className="absolute flex flex-col items-center">
        <span className="text-xl font-extrabold text-white">{Math.round(progress)}%</span>
        <span className="text-[9px] text-gray-500 uppercase tracking-widest font-semibold">Done</span>
      </div>
    </div>
  );
}
