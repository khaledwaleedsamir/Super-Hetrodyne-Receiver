% Reading the Audio files and getting sampling frequency
[sound1,fs1] = audioread("Short_FM9090.wav");
[sound2,fs2] = audioread("Short_BBCArabic2.wav");
[sound3,fs3] = audioread("Short_QuranPalestine.wav");
[sound4,fs4] = audioread("Short_RussianVoice.wav");
[sound5,fs5] = audioread("Short_SkyNewsArabia.wav");

% Adding the 2-channels of the stereo signal to have the monophonic signal
sound1_mono = sound1(:,1) + sound1(:,2);
sound2_mono = sound2(:,1) + sound2(:,2);
sound3_mono = sound3(:,1) + sound3(:,2);
sound4_mono = sound4(:,1) + sound4(:,2);
sound5_mono = sound5(:,1) + sound5(:,2);

% Padding the shorter sounds with zeros so that all sounds have same length

% First we create a cell containing all the 5 sounds
all_sounds_cell = cell(5,1);

% Fill each each cell index with a sound
for i=1:5
    sound = ['sound' num2str(i) '_mono'];
    all_sounds_cell{i} = eval(sound);
end

% iterate over the cell to check the size of each sound and find max length
max_length = 0;
for i=1:5
    [length, cols] = size(all_sounds_cell{i});
    if(length>max_length)
        max_length = length;
    end
end

% iterate over the cell again to fill the shorter sounds with zeros to make
% all sounds have the same length (Rows), columns are already 1 since we
% only have 1 channel as we are operating on the monophonic sound.
for i=1:5
    [length, cols] = size(all_sounds_cell{i});
    sound = ['sound' num2str(i) '_mono_padded'];
    num_of_zeros = max_length - length;
    all_sounds_cell{i} = [all_sounds_cell{i}; zeros(num_of_zeros,1)];
end

% Create a cell for the fft of the 5 signals and use the fft function to
% get the fft for each signal
all_sounds_FFT = cell(5,1);
for i=1:5
  all_sounds_FFT{i} = fft(all_sounds_cell{i},max_length);
end

% Shifting Zero to the center of the spectrum for plotting
% F is the frequency axis (x-axis)
% We use the function fftshift for shifting the zero to the center of the
% spectrum and we use abs to get the magnitude of the values obtained from
% the fft and divide it by the max length for normalization to ensure that
% the magnitude is from [0:1]
F = (-max_length/2:max_length/2-1)*fs1/max_length;

subplot(2,3,1)
plot(F,abs(fftshift(all_sounds_FFT{1}))/max_length);
title('Short FM9090'); xlabel('Frequency'); ylabel('Magnitude');
subplot(2,3,2)
plot(F,abs(fftshift(all_sounds_FFT{2}))/max_length);
title('Short BBCArabic2'); xlabel('Frequency'); ylabel('Magnitude');
subplot(2,3,3)
plot(F,abs(fftshift(all_sounds_FFT{3}))/max_length);
title('Short QuranPalestine'); xlabel('Frequency'); ylabel('Magnitude');
subplot(2,3,4)
plot(F,abs(fftshift(all_sounds_FFT{4}))/max_length);
title('Short RussianVoice'); xlabel('Frequency'); ylabel('Magnitude');
subplot(2,3,5)
plot(F,abs(fftshift(all_sounds_FFT{5}))/max_length);
title('Short SkyNewsArabia'); xlabel('Frequency'); ylabel('Magnitude');

