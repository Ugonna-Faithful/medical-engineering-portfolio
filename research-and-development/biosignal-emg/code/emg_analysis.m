%% Surface EMG Signal Processing and Analysis
% MATLAB analysis of surface electromyography (sEMG) across three trials:
%   - Maximum Voluntary Contraction (MVC)  -> reference for normalisation
%   - Repeated Flexion-Extension (RFE)     -> muscle activation vs joint angle
%   - Fatigue Trial (FT)                   -> spectral change (fatigue)
%
% Pipeline: load -> normalise (to MVC max) -> FFT -> Butterworth band-pass
% (20-450 Hz, 4th order) -> time-domain check -> rectify + envelope ->
% goniometer processing -> muscle identification -> median-frequency fatigue.
%
% Sampling frequency: 1000 Hz  (Nyquist 500 Hz)
% Requires: Signal Processing Toolbox (butter, filter, envelope, medfreq, fft)
%
% Author: Ugonna Faithful Ogini
% Platform: MATLAB R2025b

clear; close all; clc;

%% ------------------------------------------------------------------------
%  DATA LOADING
%  Each .mat file contains four columns: EMG1, EMG2, Goniometer, Mass.
%  -----------------------------------------------------------------------

load('Fatigue_Trial.mat')
FT_EMG1 = Fatigue_Trial(:,1);
FT_EMG2 = Fatigue_Trial(:,2);
FT_Goniometer = Fatigue_Trial(:,3);
FT_Mass = Fatigue_Trial(:,4);

load('Maximum_Voluntary_Control.mat')
MVC_EMG1 = Maximum_Voluntary_Control(:,1);
MVC_EMG2 = Maximum_Voluntary_Control(:,2);
MVC_Goniometer = Maximum_Voluntary_Control(:,3);
MVC_Mass = Maximum_Voluntary_Control(:,4);

load('Repeated_Flexion_Extension.mat')
RFE_EMG1 = Repeated_Flexion_Extension(:,1);
RFE_EMG2 = Repeated_Flexion_Extension(:,2);
RFE_Goniometer = Repeated_Flexion_Extension(:,3);
RFE_Mass = Repeated_Flexion_Extension(:,4);

%% ------------------------------------------------------------------------
%  QUESTION 1: PRE-PROCESSING - MVC ENVELOPE AND NORMALISATION
%  Normalising each channel to its MVC-envelope maximum expresses activity
%  as a fraction of peak muscle output, making trials comparable.
%  -----------------------------------------------------------------------

[MVC_EMG1_upper,MVC_EMG1_lower] = envelope(MVC_EMG1);
[MVC_EMG2_upper,MVC_EMG2_lower] = envelope(MVC_EMG2);

MVC_EMG1_max = max(MVC_EMG1_upper);
MVC_EMG2_max = max(MVC_EMG2_upper);

FT_EMG1_normalised = FT_EMG1 / MVC_EMG1_max;
FT_EMG2_normalised = FT_EMG2 / MVC_EMG2_max;

RFE_EMG1_normalised = RFE_EMG1 / MVC_EMG1_max;
RFE_EMG2_normalised = RFE_EMG2 / MVC_EMG2_max;

%% ------------------------------------------------------------------------
%  FILTER PARAMETERS
%  20 Hz high-pass removes motion artefact / baseline drift.
%  450 Hz low-pass sits below the 500 Hz Nyquist limit and retains the
%  dominant EMG energy. 4th-order Butterworth: flat passband, steep roll-off.
%  -----------------------------------------------------------------------

Fs = 1000;
high_cutoff = 20;
low_cutoff = 450;
filter_order = 4;

%% ========================================================================
%  FATIGUE TRIAL - EMG1
%  ========================================================================

% --- FFT of normalised signal ---
FT_time_EMG1_normalised = (0:length(FT_EMG1_normalised)-1)/1000;
FT_F_EMG1_normalised = abs(fft(FT_EMG1_normalised));
FT_N_EMG1_normalised = length(FT_time_EMG1_normalised);
FT_T_EMG1_normalised = max(FT_time_EMG1_normalised);
FT_dt_EMG1_normalised = FT_T_EMG1_normalised/FT_N_EMG1_normalised;
FT_df_EMG1_normalised = 1/FT_T_EMG1_normalised;
FT_fNQ_EMG1_normalised = 1/FT_dt_EMG1_normalised/2;
FT_faxis_EMG1_normalised = 0:FT_df_EMG1_normalised:FT_fNQ_EMG1_normalised;
FT_Fc_EMG1_normalised = FT_F_EMG1_normalised(1:FT_N_EMG1_normalised/2+1);

figure(1)
set(gcf,'Name','FFT of FT EMG1 Normalised')
plot(FT_faxis_EMG1_normalised,FT_Fc_EMG1_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FFT of FT EMG1 Normalised')

% --- Band-pass filter (HP then LP) ---
[b_hp_FT_EMG1,a_hp_FT_EMG1] = butter(filter_order,high_cutoff/(Fs/2),'high');
FT_EMG1_HP = filter(b_hp_FT_EMG1,a_hp_FT_EMG1,FT_EMG1_normalised);

[b_lp_FT_EMG1,a_lp_FT_EMG1] = butter(filter_order,low_cutoff/(Fs/2));
FT_EMG1_filtered = filter(b_lp_FT_EMG1,a_lp_FT_EMG1,FT_EMG1_HP);

% --- FFT of filtered signal ---
FT_time_EMG1_filtered = (0:length(FT_EMG1_filtered)-1)/1000;
FT_F_EMG1_filtered = abs(fft(FT_EMG1_filtered));
FT_N_EMG1_filtered = length(FT_time_EMG1_filtered);
FT_T_EMG1_filtered = max(FT_time_EMG1_filtered);
FT_dt_EMG1_filtered = FT_T_EMG1_filtered/FT_N_EMG1_filtered;
FT_df_EMG1_filtered = 1/FT_T_EMG1_filtered;
FT_fNQ_EMG1_filtered = 1/FT_dt_EMG1_filtered/2;
FT_faxis_EMG1_filtered = 0:FT_df_EMG1_filtered:FT_fNQ_EMG1_filtered;
FT_Fc_EMG1_filtered = FT_F_EMG1_filtered(1:FT_N_EMG1_filtered/2+1);

figure(2)
set(gcf,'Name','FT EMG1 FFT Before and After Filtering')
subplot(2,1,1)
plot(FT_faxis_EMG1_normalised, FT_Fc_EMG1_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FT EMG1 FFT Before Filtering')
subplot(2,1,2)
plot(FT_faxis_EMG1_filtered, FT_Fc_EMG1_filtered)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FT EMG1 FFT After Filtering')

% --- Time-domain comparison ---
figure(3)
set(gcf,'Name','FT EMG1 Time Domain Normalised and Filtered')
subplot(2,1,1)
plot(FT_time_EMG1_normalised,FT_EMG1_normalised)
xlabel('Time(s)')
ylabel('Amplitude')
title('FT EMG1 Time Domain Normalised')
subplot(2,1,2)
plot(FT_time_EMG1_filtered, FT_EMG1_filtered)
xlabel('Time (s)')
ylabel('Amplitude')
title('FT EMG1 Time Domain Filtered')

%% ========================================================================
%  FATIGUE TRIAL - EMG2
%  ========================================================================

% --- FFT of normalised signal ---
FT_time_EMG2_normalised = (0:length(FT_EMG2_normalised)-1)/1000;
FT_F_EMG2_normalised = abs(fft(FT_EMG2_normalised));
FT_N_EMG2_normalised = length(FT_time_EMG2_normalised);
FT_T_EMG2_normalised = max(FT_time_EMG2_normalised);
FT_dt_EMG2_normalised = FT_T_EMG2_normalised / FT_N_EMG2_normalised;
FT_df_EMG2_normalised = 1 / FT_T_EMG2_normalised;
FT_fNQ_EMG2_normalised = 1 / FT_dt_EMG2_normalised / 2;
FT_faxis_EMG2_normalised = 0:FT_df_EMG2_normalised:FT_fNQ_EMG2_normalised;
FT_Fc_EMG2_normalised = FT_F_EMG2_normalised(1:FT_N_EMG2_normalised/2+1);

figure(4)
set(gcf,'Name','FFT of FT EMG2 Normalised')
plot(FT_faxis_EMG2_normalised,FT_Fc_EMG2_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FFT of FT EMG2 Normalised')

% --- Band-pass filter ---
[b_hp_FT_EMG2,a_hp_FT_EMG2] = butter(filter_order,high_cutoff/(Fs/2),'high');
FT_EMG2_HP = filter(b_hp_FT_EMG2,a_hp_FT_EMG2,FT_EMG2_normalised);

[b_lp_FT_EMG2,a_lp_FT_EMG2] = butter(filter_order, low_cutoff/(Fs/2));
FT_EMG2_filtered = filter(b_lp_FT_EMG2,a_lp_FT_EMG2,FT_EMG2_HP);

% --- FFT of filtered signal ---
FT_time_EMG2_filtered = (0:length(FT_EMG2_filtered)-1)/1000;
FT_F_EMG2_filtered = abs(fft(FT_EMG2_filtered));
FT_N_EMG2_filtered = length(FT_time_EMG2_filtered);
FT_T_EMG2_filtered = max(FT_time_EMG2_filtered);
FT_dt_EMG2_filtered = FT_T_EMG2_filtered/FT_N_EMG2_filtered;
FT_df_EMG2_filtered = 1/FT_T_EMG2_filtered;
FT_fNQ_EMG2_filtered = 1/FT_dt_EMG2_filtered/2;
FT_faxis_EMG2_filtered = 0:FT_df_EMG2_filtered:FT_fNQ_EMG2_filtered;
FT_Fc_EMG2_filtered = FT_F_EMG2_filtered(1:FT_N_EMG2_filtered/2+1);

figure(5)
set(gcf,'Name','FT EMG2 FFT Before and After Filtering')
subplot(2,1,1)
plot(FT_faxis_EMG2_normalised, FT_Fc_EMG2_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FT EMG2 FFT Before Filtering')
subplot(2,1,2)
plot(FT_faxis_EMG2_filtered, FT_Fc_EMG2_filtered)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FT EMG2 FFT After Filtering')

% --- Time-domain comparison ---
figure(6)
set(gcf,'Name','FT EMG2 Time Domain Normalised and Filtered')
subplot(2,1,1)
plot(FT_time_EMG2_normalised,FT_EMG2_normalised)
xlabel('Time (s)')
ylabel('Amplitude')
title('FT EMG2 Time Domain Normalised')
subplot(2,1,2)
plot(FT_time_EMG2_filtered,FT_EMG2_filtered)
xlabel('Time (s)')
ylabel('Amplitude')
title('FT EMG2 Time Domain Filtered')

%% ========================================================================
%  REPEATED FLEXION-EXTENSION - EMG1
%  ========================================================================

% --- FFT of normalised signal ---
RFE_time_EMG1_normalised = (0:length(RFE_EMG1_normalised)-1)/1000;
RFE_F_EMG1_normalised = abs(fft(RFE_EMG1_normalised));
RFE_N_EMG1_normalised = length(RFE_time_EMG1_normalised);
RFE_T_EMG1_normalised = max(RFE_time_EMG1_normalised);
RFE_dt_EMG1_normalised = RFE_T_EMG1_normalised/RFE_N_EMG1_normalised;
RFE_df_EMG1_normalised = 1/RFE_T_EMG1_normalised;
RFE_fNQ_EMG1_normalised = 1/RFE_dt_EMG1_normalised/2;
RFE_faxis_EMG1_normalised = 0:RFE_df_EMG1_normalised:RFE_fNQ_EMG1_normalised;
RFE_Fc_EMG1_normalised = RFE_F_EMG1_normalised(1:RFE_N_EMG1_normalised/2+1);

figure(7)
set(gcf,'Name','FFT of RFE EMG1 Normalised')
plot(RFE_faxis_EMG1_normalised,RFE_Fc_EMG1_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FFT of RFE EMG1 Normalised')

% --- Band-pass filter ---
[b_hp_RFE_EMG1,a_hp_RFE_EMG1] = butter(filter_order,high_cutoff/(Fs/2),'high');
RFE_EMG1_HP = filter(b_hp_RFE_EMG1,a_hp_RFE_EMG1,RFE_EMG1_normalised);

[b_lp_RFE_EMG1,a_lp_RFE_EMG1] = butter(filter_order,low_cutoff/(Fs/2));
RFE_EMG1_filtered = filter(b_lp_RFE_EMG1,a_lp_RFE_EMG1,RFE_EMG1_HP);

% --- FFT of filtered signal ---
RFE_time_EMG1_filtered = (0:length(RFE_EMG1_filtered)-1)/1000;
RFE_F_EMG1_filtered = abs(fft(RFE_EMG1_filtered));
RFE_N_EMG1_filtered = length(RFE_time_EMG1_filtered);
RFE_T_EMG1_filtered = max(RFE_time_EMG1_filtered);
RFE_dt_EMG1_filtered = RFE_T_EMG1_filtered / RFE_N_EMG1_filtered;
RFE_df_EMG1_filtered = 1 / RFE_T_EMG1_filtered;
RFE_fNQ_EMG1_filtered = 1 / RFE_dt_EMG1_filtered / 2;
RFE_faxis_EMG1_filtered = 0:RFE_df_EMG1_filtered:RFE_fNQ_EMG1_filtered;
RFE_Fc_EMG1_filtered = RFE_F_EMG1_filtered(1:RFE_N_EMG1_filtered/2+1);

figure(8)
set(gcf,'Name','RFE EMG1 FFT Before and After Filtering')
subplot(2,1,1)
plot(RFE_faxis_EMG1_normalised,RFE_Fc_EMG1_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('RFE EMG1 FFT Before Filtering')
subplot(2,1,2)
plot(RFE_faxis_EMG1_filtered, RFE_Fc_EMG1_filtered)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('RFE EMG1 FFT After Filtering')

% --- Time-domain comparison ---
figure(9)
set(gcf,'Name','RFE EMG1 Time Domain Normalised and Filtered')
subplot(2,1,1)
plot(RFE_time_EMG1_normalised,RFE_EMG1_normalised)
xlabel('Time (s)')
ylabel('Amplitude')
title('RFE EMG1 Time Domain Normalised')
subplot(2,1,2)
plot(RFE_time_EMG1_filtered,RFE_EMG1_filtered)
xlabel('Time (s)')
ylabel('Amplitude')
title('RFE EMG1 Time Domain Filtered')

%% ========================================================================
%  REPEATED FLEXION-EXTENSION - EMG2
%  ========================================================================

% --- FFT of normalised signal ---
RFE_time_EMG2_normalised = (0:length(RFE_EMG2_normalised)-1)/1000;
RFE_F_EMG2_normalised = abs(fft(RFE_EMG2_normalised));
RFE_N_EMG2_normalised = length(RFE_time_EMG2_normalised);
RFE_T_EMG2_normalised = max(RFE_time_EMG2_normalised);
RFE_dt_EMG2_normalised = RFE_T_EMG2_normalised/RFE_N_EMG2_normalised;
RFE_df_EMG2_normalised = 1/RFE_T_EMG2_normalised;
RFE_fNQ_EMG2_normalised = 1/RFE_dt_EMG2_normalised/2;
RFE_faxis_EMG2_normalised = 0:RFE_df_EMG2_normalised:RFE_fNQ_EMG2_normalised;
RFE_Fc_EMG2_normalised = RFE_F_EMG2_normalised(1:RFE_N_EMG2_normalised/2+1);

figure(10)
set(gcf,'Name','FFT of RFE EMG2 Normalised')
plot(RFE_faxis_EMG2_normalised,RFE_Fc_EMG2_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('FFT of RFE EMG2 Normalised')

% --- Band-pass filter ---
[b_hp_RFE_EMG2,a_hp_RFE_EMG2] = butter(filter_order,high_cutoff/(Fs/2),'high');
RFE_EMG2_HP = filter(b_hp_RFE_EMG2,a_hp_RFE_EMG2,RFE_EMG2_normalised);

[b_lp_RFE_EMG2,a_lp_RFE_EMG2] = butter(filter_order,low_cutoff/(Fs/2));
RFE_EMG2_filtered = filter(b_lp_RFE_EMG2,a_lp_RFE_EMG2,RFE_EMG2_HP);

% --- FFT of filtered signal ---
RFE_time_EMG2_filtered = (0:length(RFE_EMG2_filtered)-1)/1000;
RFE_F_EMG2_filtered = abs(fft(RFE_EMG2_filtered));
RFE_N_EMG2_filtered = length(RFE_time_EMG2_filtered);
RFE_T_EMG2_filtered = max(RFE_time_EMG2_filtered);
RFE_dt_EMG2_filtered = RFE_T_EMG2_filtered/RFE_N_EMG2_filtered;
RFE_df_EMG2_filtered = 1/RFE_T_EMG2_filtered;
RFE_fNQ_EMG2_filtered = 1/RFE_dt_EMG2_filtered/2;
RFE_faxis_EMG2_filtered = 0:RFE_df_EMG2_filtered:RFE_fNQ_EMG2_filtered;
RFE_Fc_EMG2_filtered = RFE_F_EMG2_filtered(1:RFE_N_EMG2_filtered/2+1);

figure(11)
set(gcf,'Name','RFE EMG2 FFT Before and After Filtering')
subplot(2,1,1)
plot(RFE_faxis_EMG2_normalised,RFE_Fc_EMG2_normalised)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('RFE EMG2 FFT Before Filtering')
subplot(2,1,2)
plot(RFE_faxis_EMG2_filtered,RFE_Fc_EMG2_filtered)
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('RFE EMG2 FFT After Filtering')

% --- Time-domain comparison ---
figure(12)
set(gcf,'Name','RFE EMG2 Time Domain Normalised and Filtered')
subplot(2,1,1)
plot(RFE_time_EMG2_normalised,RFE_EMG2_normalised)
xlabel('Time (s)')
ylabel('Amplitude')
title('RFE EMG2 Time Domain Normalised')
subplot(2,1,2)
plot(RFE_time_EMG2_filtered,RFE_EMG2_filtered)
xlabel('Time (s)')
ylabel('Amplitude')
title('RFE EMG2 Time Domain Filtered')

%% ========================================================================
%  QUESTION 3: MUSCLE IDENTIFICATION
%  Rectify filtered RFE signals, take peak envelopes, and compare activation
%  timing against elbow angle recovered from the goniometer.
%  ========================================================================

RFE_EMG1_rectified = abs(RFE_EMG1_filtered);
RFE_EMG2_rectified = abs(RFE_EMG2_filtered);

[RFE_EMG1_upper,RFE_EMG1_lower] = envelope(RFE_EMG1_rectified,80,'peak');
[RFE_EMG2_upper,RFE_EMG2_lower] = envelope(RFE_EMG2_rectified,80,'peak');

RFE_time = (0:length(RFE_Goniometer)-1)/1000;

% --- Raw goniometer ---
figure(13)
set(gcf,'Name','Raw RFE Goniometer Signal')
plot(RFE_time,RFE_Goniometer)
xlabel('Time(s)')
ylabel('Goniometer Signal')
title('Raw RFE Goniometer Signal')

% --- Invert goniometer ---
RFE_Goniometer_inverted = -RFE_Goniometer;

figure(14)
set(gcf,'Name','Inverted RFE Goniometer Signal')
plot(RFE_time,RFE_Goniometer_inverted)
xlabel('Time(s)')
ylabel('Inverted Goniometer Signal')
title('Inverted RFE Goniometer Signal')

% --- Rescale to 0-120 degrees ---
RFE_angle = (RFE_Goniometer_inverted - min(RFE_Goniometer_inverted)) ...
    / (max(RFE_Goniometer_inverted) - min(RFE_Goniometer_inverted));
RFE_angle = RFE_angle * 120;

figure(15)
set(gcf,'Name','RFE Elbow Angle 0 to 120 Degrees')
plot(RFE_time,RFE_angle)
xlabel('Time (s)')
ylabel('Elbow Angle (degrees)')
title('RFE Elbow Angle')

% --- Compare EMG envelopes with elbow angle ---
figure(16)
set(gcf,'Name','EMG Envelope Activity Compared with Elbow Angle')
subplot(2,1,1)
plot(RFE_time,RFE_EMG1_upper,'LineWidth',1.5)
hold on
plot(RFE_time,RFE_EMG2_upper,'LineWidth', 1.5)
xlabel('Time (s)')
ylabel('EMG Envelope')
title('EMG Activity')
legend('EMG1','EMG2')
hold off
subplot(2,1,2)
plot(RFE_time,RFE_angle,'LineWidth', 1.5)
xlabel('Time (s)')
ylabel('Elbow Angle (degrees)')
title('Elbow Flexion/Extension Angle')

% EMG1 -> biceps brachii (greater activity toward 120 deg, flexion)
% EMG2 -> triceps brachii (greater activity toward 0 deg, extension)

%% ========================================================================
%  QUESTION 4: FATIGUE ANALYSIS (median frequency)
%  Seven 10-second segments from the Fatigue Trial; median frequency of each
%  quantifies the spectral shift associated with fatigue.
%  ========================================================================

% --- EMG1 segments ---
FT_EMG1_20 = FT_EMG1_filtered(20001:30000);
FT_EMG1_40 = FT_EMG1_filtered(40001:50000);
FT_EMG1_60 = FT_EMG1_filtered(60001:70000);
FT_EMG1_80 = FT_EMG1_filtered(80001:90000);
FT_EMG1_100 = FT_EMG1_filtered(100001:110000);
FT_EMG1_120 = FT_EMG1_filtered(120001:130000);
FT_EMG1_140 = FT_EMG1_filtered(140001:150000);

MF_EMG1_20 = medfreq(FT_EMG1_20,Fs);
MF_EMG1_40 = medfreq(FT_EMG1_40,Fs);
MF_EMG1_60 = medfreq(FT_EMG1_60,Fs);
MF_EMG1_80 = medfreq(FT_EMG1_80,Fs);
MF_EMG1_100 = medfreq(FT_EMG1_100,Fs);
MF_EMG1_120 = medfreq(FT_EMG1_120,Fs);
MF_EMG1_140 = medfreq(FT_EMG1_140,Fs);

MF_EMG1 = [MF_EMG1_20 ...
    MF_EMG1_40 ...
    MF_EMG1_60 ...
    MF_EMG1_80 ...
    MF_EMG1_100 ...
    MF_EMG1_120 ...
    MF_EMG1_140];

fatigue_time = [20 40 60 80 100 120 140];

% --- EMG2 segments ---
FT_EMG2_20 = FT_EMG2_filtered(20001:30000);
FT_EMG2_40 = FT_EMG2_filtered(40001:50000);
FT_EMG2_60 = FT_EMG2_filtered(60001:70000);
FT_EMG2_80 = FT_EMG2_filtered(80001:90000);
FT_EMG2_100 = FT_EMG2_filtered(100001:110000);
FT_EMG2_120 = FT_EMG2_filtered(120001:130000);
FT_EMG2_140 = FT_EMG2_filtered(140001:150000);

MF_EMG2_20 = medfreq(FT_EMG2_20,Fs);
MF_EMG2_40 = medfreq(FT_EMG2_40,Fs);
MF_EMG2_60 = medfreq(FT_EMG2_60,Fs);
MF_EMG2_80 = medfreq(FT_EMG2_80,Fs);
MF_EMG2_100 = medfreq(FT_EMG2_100,Fs);
MF_EMG2_120 = medfreq(FT_EMG2_120,Fs);
MF_EMG2_140 = medfreq(FT_EMG2_140,Fs);

MF_EMG2 = [MF_EMG2_20 ...
    MF_EMG2_40 ...
    MF_EMG2_60 ...
    MF_EMG2_80 ...
    MF_EMG2_100 ...
    MF_EMG2_120 ...
    MF_EMG2_140];

figure(17)
set(gcf,'Name','Median Frequency During Fatigue Trial')
plot(fatigue_time,MF_EMG1,'o-','Linewidth',1.5)
hold on
plot(fatigue_time,MF_EMG2,'o-','Linewidth',1.5)
xlabel('Time (s)')
ylabel('Median Frequency (Hz)')
title('Median Frequency During Fatigue Trial')
legend('EMG1', 'EMG2')
hold off

% Median frequency falls over the trial in both channels (fibre conduction
% velocity decreases with fatigue), shifting the spectrum to lower frequencies.
