%% READING THE AUDIO FILES
% Define file paths in a cell array
filePaths = {
    'Short_BBCArabic2.wav',...
    'Short_FM9090.wav',...
    'Short_QuranPalestine.wav',...
    'Short_RussianVoice.wav',...
    'Short_SkyNewsArabia.wav'...
};
numFiles = length(filePaths);

% use interp to increase Fs to 18 times
FS_Multiplier = 18;

% Initialize arrays to store audio signals and sampling frequencies
audioData = cell(1, numFiles);
samplingFreq = zeros(1, numFiles);

% Read audio signals and obtain sampling frequencies using a for loop
for i = 1:numFiles
    [audioData{i}, samplingFreq(i)] = audioread(filePaths{i});
    
    % Combine stereo channels into monophonic signals
    audioData{i} = sum(audioData{i}, 2);
    % Increase the sampling frequency     
    audioData{i} = interp(audioData{i}, FS_Multiplier);
end

% Calculate the New Sampling Frequency
samplingFreq = samplingFreq*FS_Multiplier;

% Compute the maximum length among all signals after interpolation
max_length = max(cellfun(@(x) length(audioData{strcmp(filePaths, x)}), filePaths));

% Zero Padding
for i = 1:numFiles
    % Pad the shorter signals with zeros
    audioData{i} = [audioData{i}; zeros(max_length - length(audioData{i}), 1)];
end

%*************************************************************************%
%                       Plotting the signals to test                      %
%*************************************************************************%
 figure;
 F = (-max_length/2:max_length/2-1) * samplingFreq(i) / max_length;
 F = F';
     
for i = 1:numFiles
    subplot(3, 2, i);
    fft_mono_audio = fftshift(fft(audioData{i}));
    magnitude = abs(fft_mono_audio)/max_length;
    plot(F, magnitude);
    title(['Spectrum of Mono-audio ' num2str(i)]);
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
end
sgtitle('Spectrum Analysis of Audio Signals after interpolation');

%% AM DSB-SC MODULATION
% Define modulation parameters
fc_first = 100e3;  % Frequency of the first carrier (100 KHz)
delta_f = 55e3;    % Frequency spacing between carriers (55 KHz)

% Calculate carrier frequency for each signal before the loop
fc_n_values = fc_first + (0:numFiles-1) * delta_f;

% Modulate each audio signal with DSB-SC modulation
modulated_signals = cell(1, numFiles);

for i = 1:numFiles
    % Use the precalculated carrier frequency
    fc_n = fc_n_values(i);

    % Generate the carrier signal
    t = (0:length(audioData{i}) - 1) / samplingFreq(i);
    carrier = cos(2 * pi * fc_n * t);
    carrier = carrier';

    % DSB-SC modulation
    modulated_signals{i} = audioData{i} .* carrier;
end

% Sum up the modulated signals for FDM
fdm_signal = sum(cat(3, modulated_signals{:}), 3);

%*************************************************************************%
%             Plot the spectrum of the signals using a for loop           %
%*************************************************************************%
figure;
F = (-max_length/2:max_length/2-1) * samplingFreq(1) / max_length;
F = F';
    
for i = 1:numFiles
    subplot(3, 2, i);
    fft_mono_audio = fftshift(fft(modulated_signals{i}));
    magnitude = abs(fft_mono_audio)/max_length;
    plot(F, magnitude);
    title(['Spectrum of modulated audio ' num2str(i)]);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
end

%*************************************************************************%
%          Plotting FDM Signal in Time domain and frequency domain        %
%*************************************************************************%
t = (0:length(audioData{1}) - 1) / samplingFreq(1);
figure;
subplot(2,1,1);
plot(t,fdm_signal);
title('FDM Signal in Time domain');
xlabel('Time'); ylabel('Amplitude');
fft_fdm_signal = fftshift(fft(fdm_signal));
subplot(2,1,2);
plot(F, abs(fft_fdm_signal)/max_length);
title('FDM Signal Spectrum');
xlabel('Frequency (Hz)');
ylabel('Amplitude');

%% RF STAGE (BANDPASS FILTER)
filtered_audios = cell(1, numFiles);

% filter parameters for each one of the 5 signals
PASS1_FREQUENCIES = [92315.8,147600,205324,257198,318430];
PASS2_FREQUENCIES = [107687,162128,214707,273334,321520];


STOP1_FREQUENCIES = [79170,125939,182237,232925,3e5];
STOP2_FREQUENCIES = [125939,182237,232925,3e5,343028];


A_stop1 = 60;		% Attenuation in the first stopband = 60 dB
A_stop2 = 60;		% Attenuation in the second stopband = 60 dB
A_pass = 1;         % Amount of ripple allowed in the passband = 1 dB

% creating a filter for each signal and applying it to the FDM signal, and
% saving the filtered signal in the filtered audio cell.
for i = 1:numFiles
    BandPassSpecObj = ...
       fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
            STOP1_FREQUENCIES(i), PASS1_FREQUENCIES(i), PASS2_FREQUENCIES(i)...
            , STOP2_FREQUENCIES(i), A_stop1, A_pass, ...
            A_stop2, 793800);%793800 is the sampling frequency after interp
   
    BandPassFilter = design(BandPassSpecObj, 'equiripple');
    filtered_audios{i} = filter(BandPassFilter, fdm_signal);
end

%*************************************************************************%
%        Plotting Filtered signals after applying the RF-BP filter        %
%*************************************************************************%
figure;
F = (-max_length/2:max_length/2-1) * samplingFreq(1) / max_length;
F = F';
for i = 1:numFiles
    subplot(3, 2, i);
    fft_fdm_signal = fftshift(fft(filtered_audios{i}));
    magnitude = abs(fft_fdm_signal)/max_length;
    plot(F, magnitude);
    title(['RF-Filtered audio ' num2str(i)]);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
end

%% OSCILLATOR

demodulated_signals = cell(1, numFiles);

% Calculate carrier frequency for each signal before the loop
WIF = 27.5e3;
GENERATOR_FREQENCIES = fc_first + (0:numFiles-1) * delta_f + WIF;

for i = 1:numFiles
    % Use the precalculated carrier frequency
    fc_n = GENERATOR_FREQENCIES(i);

    % Generate the carrier signal
    t = (0:length(filtered_audios{i}) - 1) / samplingFreq(i);
    carrier = cos(2 * pi * fc_n * t);
    carrier = carrier';

    % demodulation
    demodulated_signals{i} = filtered_audios{i} .* carrier;
end

%*************************************************************************%
%        Plotting Demodulated Signals at Intermediate Frequency WIF       %
%*************************************************************************%
figure;
for i = 1:numFiles
    subplot(3, 2, i);
    fft_fdm_signal = fftshift(fft(demodulated_signals{i}));
    magnitude = abs(fft_fdm_signal)/max_length;
    plot(F, magnitude);
    title(['Demodulated audio ' num2str(i)]);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
end

%% IF STAGE
BAND_WIDTHS_PASS = PASS2_FREQUENCIES - PASS1_FREQUENCIES;
BAND_WIDTHS_STOP = STOP2_FREQUENCIES - STOP1_FREQUENCIES;

% Modulate each audio signal with DSB-SC modulation
filtered_audios_IF = cell(1, numFiles);

for i = 1:numFiles
    BandPassSpecObj = ...
       fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
           1, WIF - BAND_WIDTHS_PASS(i)/2,...
            WIF + BAND_WIDTHS_PASS(i)/2, WIF + BAND_WIDTHS_STOP(i)/2, ...
            A_stop1, A_pass,A_stop2, 793800);

    BandPassFilter_IF = design(BandPassSpecObj, 'equiripple');
    filtered_audios_IF{i} = filter(BandPassFilter_IF, demodulated_signals{i});
end

%*************************************************************************%
%        Plotting Filtered signals after applying the IF-BP filter        %
%*************************************************************************%
figure;
F = (-max_length/2:max_length/2-1) * samplingFreq(1) / max_length;
F = F';
for i = 1:numFiles
    subplot(3, 2, i);
    fft_fdm_signal = fftshift(fft(filtered_audios_IF{i}));
    magnitude = abs(fft_fdm_signal)/max_length;
    plot(F, magnitude);
    title(['Filtered audio ' num2str(i) ' at IF']);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
end

%% BASEBAND DETECTION
BASEBAND_SIGNALS = cell(1, numFiles);
filtered_audios_BB = cell(1, numFiles);

for i = 1:numFiles
    % Use the precalculated carrier frequency
    % Generate the carrier signal
    t = (0:length(filtered_audios_IF{i}) - 1) / samplingFreq(i);
    carrier = cos(2 * pi * WIF * t);
    carrier = carrier';

    % demodulation
    BASEBAND_SIGNALS{i} = filtered_audios_IF{i} .* carrier;
end

% LOW PASS FILTER
for i = 1:numFiles
    LowPassSpecObj = ...
       fdesign.lowpass('Fp,Fst,Ap,Ast', ...
            10000,...
            20000,...
            A_pass,A_stop2, 793800);

    LowPassFilter_BB = design(LowPassSpecObj, 'equiripple');
    filtered_audios_BB{i} = filter(LowPassFilter_BB, BASEBAND_SIGNALS{i});
end
%*************************************************************************%
%            Plotting Baseband signals after applying the LPF             %
%*************************************************************************%
figure;
F = (-max_length/2:max_length/2-1) * samplingFreq(1) / max_length;
F = F';
for i = 1:numFiles
    subplot(3, 2, i);
    fft_fdm_signal = fftshift(fft(filtered_audios_BB{i}));
    magnitude = abs(fft_fdm_signal)/max_length;
    plot(F, magnitude);
    title(['Filtered audio ' num2str(i) ' at Baseband']);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
end
%% REVERSING THE INTERPOLATION
Received_Signals = cell(1, numFiles);
% Reverse the interpolation
for i = 1:numFiles
    Received_Signals{i} = resample(filtered_audios_BB{i}, 1, FS_Multiplier);
end
samplingFreq = samplingFreq/FS_Multiplier;

%*************************************************************************%
%                    Plotting Original signals Spectrum                   %
%*************************************************************************%
figure;
max_length = max(cellfun(@(x) length(Received_Signals{strcmp(filePaths, x)}), filePaths));
F = (-max_length/2:max_length/2-1) * samplingFreq(1) / max_length;
F = F';
for i = 1:numFiles
    subplot(3, 2, i);
    fft_BB = fftshift(fft(Received_Signals{i}));
    magnitude = abs(fft_BB)/max_length;
    plot(F, magnitude);
    title(['Original audio '  num2str(i)  ' at Baseband']);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
end

%% Playing the received signal
sound(Received_Signals{4}, samplingFreq(4));
