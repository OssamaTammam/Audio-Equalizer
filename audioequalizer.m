% Close all figures, clear all variables and the command window
close all;
clear all;
clc;

% Ask the user to select the audio signal file
audioFile = uigetfile;
[Signal, sampleRate] = audioread(audioFile); % Read the signal
fprintf('Audio Sample Rate: %d\n', sampleRate);
gain = []; % Array to store the gain values for each frequency band
titles = {'170', '170-310', '310-600', '600-1000', '1000-3000', '3000-6000', '6000-12000', '12000-14000', '14000-20000'};

% Ask the user to enter the gain values for each frequency band
for i = 1:9
    str = sprintf('Please enter the gain (in dB) for the frequency band (%s)Hz: ', titles{i});
    gain(i) = str2double(input(str, 's'));

    while (isnan(gain(i)))% Check if the input is a number
        str = sprintf('Error! Please enter the gain (in dB) for the frequency band (%s)Hz: ', titles{i});
        gain(i) = str2double(input(str, 's'));
    end

    gain(i) = db2mag(gain(i)); % Convert the gain from dB to magnitude
end

% Ask the user to enter the desired output sample rate
newFs = str2double(input('\nPlease enter the desired output sample rate (must be in the range 80-1000000): ', 's'));

% Check if the input is a number and if it is in the range 80-1000000
while (newFs == 0 || newFs <= 80 || newFs >= 1000000 || isnan(newFs))
    newFs = str2double(input('Invalid input! Please enter the desired output sample rate: ', 's'));
end

% Ask the user to select the type of filter
filterType = str2double(input('\nPlease enter the type of filter (1. FIR / 2. IIR): ', 's'));

% Check if the input is a number and if it is 1 or 2
while ((filterType ~= 1 && filterType ~= 2) || isnan(filterType))
    filterType = str2double(input('Invalid input! Please enter the type of filter (1. FIR / 2. IIR): ', 's'));
end

tempFs = 48000; % Temporary sample rate greater than 2*Fm
resampledSignal = resample(Signal, tempFs, sampleRate); % Resample the signal to the temporary sample rate
Fs = tempFs; % Set the sample rate to the temporary sample rate

% Calculate the normalized frequencies for each frequency band
Fn = Fs / 2; % Nyquist frequency is half of the sample rate
wn1 = 170 / Fn;
wn2 = [170 310] / Fn;
wn3 = [310 600] / Fn;
wn4 = [600 1000] / Fn;
wn5 = [1000 3000] / Fn;
wn6 = [3000 6000] / Fn;
wn7 = [6000 12000] / Fn;
wn8 = [12000 14000] / Fn;
wn9 = [14000 20000] / Fn;

% Initialize the output signal and the output signal gain
outputSignal = 0;
outputSignalGain = 0;

if (filterType == 1)% FIR filter ~ Finitie Impulse Respone filter
    order = 100; % Set the order to 100

    for i = 1:9

        % Calculate the filter coefficients for each frequency band
        if (i == 1)
            num = fir1(order, wn1, 'low');
        elseif (i == 2)
            num = fir1(order, wn2, 'bandpass');
        elseif (i == 3)
            num = fir1(order, wn3, 'bandpass');
        elseif (i == 4)
            num = fir1(order, wn4, 'bandpass');
        elseif (i == 5)
            num = fir1(order, wn5, 'bandpass');
        elseif (i == 6)
            num = fir1(order, wn6, 'bandpass');
        elseif (i == 7)
            num = fir1(order, wn7, 'bandpass');
        elseif (i == 8)
            num = fir1(order, wn8, 'bandpass');
        else
            num = fir1(order, wn9, 'bandpass');
        end

        den = 1; % Set the denominator to 1
        filteredOutputSignal = filter(num, 1, resampledSignal); % Filter the resampled signal
        outputSignal = outputSignal + filteredOutputSignal; % Add the filtered signal to the output signal
        outputSignalGain = outputSignalGain + gain(i) * filteredOutputSignal; % Add the filtered signal multiplied by the gain to the output signal gain

        % Plot the magnitude and phase, impulse response, step response, zero-pole plot, filtered input in time domain and filtered input in frequency domain
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);
        freqz(num, den);
        title(sprintf('(FIR) Magnitude and Phase for (%s)Hz', titles{i}));
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);

        [h, t] = impz(num, den);
        subplot(2, 3, 1); stem(t, h);
        title(sprintf('(FIR) Impulse Response for (%s)Hz', titles{i}));

        [s, t] = stepz(num, den);
        subplot(2, 3, 2); stem(t, s);
        title(sprintf('(FIR) Step response for (%s)Hz', titles{i}));

        fprintf('\n(FIR) Order for (%s)Hz = %d\n', titles{i}, order);
        TF = tf(num, den);
        [zero1, gains] = zero(TF);
        fprintf('(FIR) Gain for (%s)Hz = %d\n\n', titles{i}, gains);
        t = linspace(0, length(filteredOutputSignal) / Fs, length(filteredOutputSignal));
        f = linspace(-Fs / 2, Fs / 2, length(filteredOutputSignal));
        subplot(2, 3, 3); zplane(roots(num), roots(den));
        title(sprintf('(FIR) Zero-Pole plot (%s)Hz', titles{i}));
        subplot(2, 3, 4); plot(t, filteredOutputSignal);
        title(sprintf('(FIR) Filtered input in Time Domain for (%s)Hz', titles{i}));
        subplot(2, 3, 5); plot(f, abs(fftshift(fft(filteredOutputSignal))));
        title(sprintf('(FIR) Filtered input in Freq Domain for (%s)Hz', titles{i}));
    end

else % IIR filter ~ Infinite Impulse Respone filter

    for i = 1:9
        order = 2; % Set the order to 2

        % Calculate the filter coefficients for each frequency band
        if (i == 1)
            [num, den] = butter(order, wn1, 'low');
            [z, p, k] = butter(order, wn1, 'low');
        elseif (i == 2)
            [num, den] = butter(order, wn2, 'bandpass');
            [z, p, k] = butter(order, wn2, 'bandpass');
        elseif (i == 3)
            [num, den] = butter(order, wn3, 'bandpass');
            [z, p, k] = butter(order, wn3, 'bandpass');
        elseif (i == 4)
            [num, den] = butter(order, wn4, 'bandpass');
            [z, p, k] = butter(order, wn4, 'bandpass');
        elseif (i == 5)
            [num, den] = butter(order, wn5, 'bandpass');
            [z, p, k] = butter(order, wn5, 'bandpass');
        elseif (i == 6)
            [num, den] = butter(order, wn6, 'bandpass');
            [z, p, k] = butter(order, wn6, 'bandpass');
        elseif (i == 7)
            [num, den] = butter(order, wn7, 'bandpass');
            [z, p, k] = butter(order, wn7, 'bandpass');
        elseif (i == 8)
            [num, den] = butter(order, wn8, 'bandpass');
            [z, p, k] = butter(order, wn8, 'bandpass');
        else
            [num, den] = butter(order, wn9, 'bandpass');
            [z, p, k] = butter(order, wn9, 'bandpass');
        end

        filteredOutputSignal = filter(num, den, resampledSignal); % Filter the resampled signal
        outputSignal = outputSignal + filteredOutputSignal; % Add the filtered signal to the output signal
        outputSignalGain = outputSignalGain + gain(i) * filteredOutputSignal; % Add the filtered signal multiplied by the gain to the output signal gain

        % Plot the magnitude and phase, impulse response, step response, zero-pole plot, filtered input in time domain and filtered input in frequency domain
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);
        freqz(num, den);
        title(sprintf('(IIR) Magnitude and Phase for (%s)Hz', titles{i}));
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);

        [h, t] = impz(num, den);
        subplot(2, 3, 1); stem(t, h);
        title(sprintf('(IIR) Impulse Response for (%s)Hz', titles{i}));

        [s, t] = stepz(num, den);
        subplot(2, 3, 2); stem(t, s);
        title(sprintf('(IIR) Step response (%s)Hz', titles{i}));

        fprintf('(IIR) Order for (%s)Hz = %d\n', titles{i}, order);

        subplot(2, 3, 3); zplane(z, p);
        title(sprintf('(IIR) Zero-Pole plot %s', titles{i}));
        t = linspace(0, length(filteredOutputSignal) / Fs, length(filteredOutputSignal));
        f = linspace(-Fs / 2, Fs / 2, length(filteredOutputSignal));
        fprintf('(IIR) Gain for (%s)Hz= %d\n\n', titles{i}, k);
        subplot(2, 3, 4); plot(t, filteredOutputSignal);
        title(sprintf('(IIR) Filtered input in Time Domain for (%s)Hz', titles{i}));
        subplot(2, 3, 5); plot(f, abs(fftshift(fft(filteredOutputSignal))));
        title(sprintf('(IIR) Filtered input in Freq Domain for (%s)Hz', titles{i}));
    end

end

% Plot the input signal in time domain and frequency domain, the composite signal in time domain and frequency domain
tSignal = linspace(0, length(Signal) / sampleRate, length(Signal));
fSignal = linspace(-sampleRate / 2, sampleRate / 2, length(Signal));
outputSignalGain = resample(outputSignalGain, newFs, tempFs);

tCompositeSignal = linspace(0, length(outputSignalGain) / newFs, length(outputSignalGain));
fCompositeSignal = linspace(-newFs / 2, newFs / 2, length(outputSignalGain));

figure('units', 'normalized', 'outerposition', [0 0 1 1]);
subplot(2, 2, 1); plot(tSignal, Signal);
title('Input signal in Time Domain');
subplot(2, 2, 2); plot(fSignal, abs(fftshift(fft(Signal))));
title('Input Signal in Freq Domain');

subplot(2, 2, 3); plot(tCompositeSignal, outputSignalGain);
title('Composite signal in Time Domain');
subplot(2, 2, 4); plot(fCompositeSignal, abs(fftshift(fft(outputSignalGain))));
title('Composite Signal in Freq Domain');

% Play the composite signal
sound(outputSignalGain, newFs);

% Save the output signal as a wave file
audiowrite('output.wav', outputSignalGain, newFs)
