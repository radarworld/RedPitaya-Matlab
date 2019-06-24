
clc
clear all
close all

IP= '192.168.178.27';           % Input IP of your Red Pitaya...
port = 5000;
tcpipObj=tcpip(IP, port);
tcpipObj.InputBufferSize = 16384*32;
tcpipObj.OutputBufferSize = 8192*32;

%% Open connection with your Red Pitaya and close prev.
x=instrfind;
fclose(x);
fopen(tcpipObj);
tcpipObj.Terminator = 'CR/LF';
flushinput(tcpipObj)
flushoutput(tcpipObj)

%% Calculate arbitrary waveform with 16384 samples


t=(0:3.90625e-6:(64e-3) - 3.90625e-6 ); % time
x= (sawtooth(2*pi*4e3*t)+1)/2; % sawtooth wave
%plot(t,x)
%%Convert waveforms to string with 5 decimal places accuracy
waveform_ch_1_0 = num2str(x,'%1.5f,');
%latest are empty places","
waveform_ch_1_0 = waveform_ch_1_0(1,1:length(waveform_ch_1_0)-3);


%% The example generate sine bursts every 0.5 seconds indefinety
fprintf(tcpipObj,'GEN:RST');
fprintf(tcpipObj,'ACQ:RST');

fprintf(tcpipObj,'SOUR1:FUNC ARBITRARY');
fprintf(tcpipObj,['SOUR1:TRAC:DATA:DATA ', waveform_ch_1_0]);     % Set frequency of output signal
fprintf(tcpipObj,'SOUR1:VOLT 1');          % Set amplitude of output signal
fprintf(tcpipObj,'SOUR1:FREQ:FIX 15.625');    %T=1/64mSec fot thr burst
%fprintf(tcpipObj,'SOUR1:BURS:STAT ON');          
%fprintf(tcpipObj,'SOUR1:BURS:NCY 1');          
%fprintf(tcpipObj,'SOUR1:BURS:NOR 1');          
%fprintf(tcpipObj,'SOUR1:BURS:INT:PER 6400000');      
%fprintf(tcpipObj,'SOUR1:TRIG:SOUR INT');      
%fprintf(tcpipObj,'SOUR1:TRIG:IMM');           % Set generator trigger to immediately




%% Set Acquire
fprintf(tcpipObj,'ACQ:DEC 1024');

%fprintf(tcpipObj,'ACQ:TRIG:LEV 0');
fprintf(tcpipObj,'ACQ:TRIG:DLY 8192');
fprintf(tcpipObj,'ACQ:SOUR1:GAIN HV');
fprintf(tcpipObj,'ACQ:SOUR2:GAIN HV');
fprintf(tcpipObj,'OUTPUT1:STATE ON');
fprintf(tcpipObj,'ACQ:START');
pause(0.1)
fprintf(tcpipObj,'ACQ:TRIG NOW');

while 1
    clc
  
    trig_rsp=query(tcpipObj, 'ACQ:TRIG:STAT?')
    if strcmp('TD', trig_rsp(1:2))
        current_write_pos = query(tcpipObj, 'ACQ:WPOS?')
        trig_pos = query(tcpipObj, 'ACQ:TPOS?')
        buffer_size = query(tcpipObj, 'ACQ:BUF:SIZE?')
        triiger_delay = query(tcpipObj, 'ACQ:TRIG:DLY?')
        %signal_str_ch1 = query(tcpipObj, 'ACQ:SOUR1:DATA?');
        %signal_str_ch2 = query(tcpipObj, 'ACQ:SOUR2:DATA?');
        signal_str_ch1 = query(tcpipObj, 'ACQ:SOUR1:DATA:STA:N? 1,8192');%read only the half of the buffer 
        signal_str_ch2 = query(tcpipObj, 'ACQ:SOUR2:DATA:STA:N? 1,8192');
        
        signal_num_ch1=str2num(signal_str_ch1(1,2:length(signal_str_ch1)-3));
        signal_num_ch2=str2num(signal_str_ch2(1,2:length(signal_str_ch2)-3));
       % plot(signal_num_ch1)
       % hold on
       % plot(signal_num_ch2,'g')
        
        
        fprintf(tcpipObj,'ACQ:START');
        fprintf(tcpipObj,'ACQ:TRIG LEV 0');
        pause(0.01)
        break
     end
end



%inrange = (signal_num_ch1>0.1) & (signal_num_ch1<0.9)
start=((signal_num_ch1>0.1) & (signal_num_ch1<0.9));
lastvalue=1;
col=1;
row=1;
for ii= 1: size(signal_num_ch1,2)-1
    if (signal_num_ch1(ii) - signal_num_ch1(ii+1) ) >0
        sign_n(ii)=0;        
    else
        %if rising edge store signals
        sign_n(ii)=1;
    end
end


for ii= 2: size(signal_num_ch2,2)-2
    if sign_n(ii-1)==0 & sign_n(ii)==1 %elozo 0 most 1: write one data to current row
        sif(row,col)=signal_num_ch2(ii);
        col=col+1;
    elseif sign_n(ii-1)==1 & sign_n(ii)==1 %elozo 1 most 1: write datas to current row and row++
        sif(row,col)=signal_num_ch2(ii);
        row=row+1;
    elseif sign_n(ii-1)==1 & sign_n(ii)==0 %elozo 1 most 0: ne irj semmit csak row=1
        row=1;
        
    end
end

 sif=sif(:,2:257);       
 sif=vertcat(sif,zeros(3,256));
 
 test=fft(sif,32,1)


        

    

%% Close connection with Red Pitaya
fclose(tcpipObj);
