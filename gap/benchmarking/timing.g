GAUSS_GET_REAL_TIME_OF_FUNCTION_CALL := function ( method, args, options... )
  local first_time, firstSeconds,
    firstMicroSeconds, result, second_time, secondSeconds,
  secondMicroSeconds, total, seconds, microSeconds;

  if options = [] then
    options := rec();
  else
    options := options[1];
  fi;
  if not IsBound( options.passResult ) then
    options.passResult := false;
  fi;

  first_time := IO_gettimeofday(  );
  firstSeconds := first_time.tv_sec;
  firstMicroSeconds := first_time.tv_usec;

  result := CallFuncList( method, args );

  second_time := IO_gettimeofday(  );
  secondSeconds := second_time.tv_sec;
  secondMicroSeconds := second_time.tv_usec;

  seconds := (secondSeconds - firstSeconds);
  microSeconds := secondMicroSeconds - firstMicroSeconds;
  total := seconds * 10^6 + microSeconds;
  return rec( result := result, time := total );
end;

GAUSS_threeSignificantDigits := function( x )
  local count;
  if not IsFloat(x) then
    Error( "x must be a Float.\n" );
  fi;
  count := 0;
  while x >= 10. do
    x := x/10;
    count := count + 1;
  od;
  # Round to three significant digits
  x := Floor( x * 100 );
  return x * 10^(count-2);
end;

GAUSS_GetStatistics := function( data )
  local statistics;
  ## Fill the statistics vector
  Sort( data );
  # maximal string length = 12
  statistics := [
    Minimum( data ),
    0.,
    Average( data ),
    Median( data ),
    0.,
    Maximum( data )
  ];
  if Length( data ) >= 4 then
    statistics[2] := data[ Int( 0.25 * Length(data) ) ];
    statistics[5] := data[ Int( 0.75 * Length(data) ) ];
  fi;
  statistics := 1. * statistics;
  statistics := List( statistics, GAUSS_threeSignificantDigits );
  return statistics;
end;

## R-microbenchmark like statistics
GAUSS_Benchmark := function( func, args, opt... )
  local timings, columnNames, statistics, i, t, res;
  Info(InfoGauss, 2, "Start Benchmark in timing.g");
  if opt = [] then
    opt := rec();
  else
    opt := opt[1];
  fi;
  if not IsBound( opt.warmup ) then
    opt.warmup := 0;
  fi;
  if not IsBound( opt.times ) then
    opt.times := 5;
  fi;
  timings := [];
  statistics := [];

  ## Perform the computations
  if opt.warmup > 0 then
    for i in [1 .. opt.warmup] do
      GAUSS_GET_REAL_TIME_OF_FUNCTION_CALL( func, args );
    od;
  fi;
  for i in [ 1 .. opt.times ] do
    res := GAUSS_GET_REAL_TIME_OF_FUNCTION_CALL( func, args );
    Info(InfoGauss, 2, "GET_REAL_TIME_OF_FUNCTION_CALL calculation ", i);
    t := res.time;
    # We don't care about microseconds
    t := Floor( 1.0 * t / 1000 );
    timings[ Length(timings)+1 ] := t;
  od;

  statistics := GAUSS_GetStatistics( timings );

  res := rec( timings := timings, statistics := statistics );
  return res;
end;

## Calculates time statistics for one matrix of a specific type using Benchmark()
GAUSS_CalculateTime := function(isParallel, height, width, rank, ring, numberBlocksH, numberBlocksW, randomSeed)
    local echelon, shapeless, result, times, r;
    Info(InfoGauss, 2, "Start CalculateTime");
    times := 0;

    # Create random matrices, calculate time.
    echelon := RandomEchelonMat(height, width, rank, randomSeed, ring);;
    Info(InfoGauss, 4, "Echelon matrix:");
    Info(InfoGauss, 4, echelon);
    shapeless := GAUSS_RandomMatFromEchelonForm(echelon, height);;
    Info(InfoGauss, 4, "Shapeless matrx:");
    Info(InfoGauss, 4, shapeless);
    if isParallel then
        Info(InfoGauss, 3, "Parallel version:");
    else
        Info(InfoGauss, 3, "Sequential version:");
    fi;
    times := GAUSS_Benchmark(
        DoEchelonMatTransformationBlockwise,
        [
            shapeless,
            rec( galoisField := ring, IsHPC := isParallel,
            numberBlocksHeight := numberBlocksH,
            numberBlocksWidth := numberBlocksW )
        ]
    );

    return times.timings;
end;

## Calculates time statistics for 10 matrices of a specific type
GAUSS_CalculateAverageTime := function(isParallel, height, width, rank, ring, numberBlocksH, numberBlocksW)
    local randomSeed, timings, statistics, i;

    Info(InfoGauss, 2, "Start CalculateAverageTime in stats/timing.g");

    randomSeed := RandomSource(IsMersenneTwister);;
    timings := [];

    # Do a few times and calculate average.
    for i in [ 1 .. 10 ] do
        Info(InfoGauss, 3, "CalculateTime calculation no.", i);
        Append(timings, GAUSS_CalculateTime(isParallel, height, width, rank, ring, numberBlocksH, numberBlocksW, randomSeed));
    od;

    statistics := GAUSS_GetStatistics(timings);
    return statistics;
end;
