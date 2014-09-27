classdef encoder < hgsetget
    %ENCODER class to interface with the encoder for the air bearing
    
    properties(GetAccess=private,SetAccess=private,Hidden)
        %serial port handle
        ser
        %history for timestamp and angle to calculate rates
        T=[];
        A=[];
    end
    properties(SetAccess=private)
        %current angular rate in deg/sec
        rate=[];
        %current angle in deg
        angle=[];
        %current angular acceleration
        acc=[];
        %current time stamp in secconds
        TimeStamp=[];
        %responses
        resp={};
    end
    properties
        index
    end
    properties(Constant,Hidden)
        %name of device. this will be sent out when the port is opened
        devname='QSB-D  09!';   
        %dt for timestamp
        dt=1/512;
        %counts/revolution
        %the wheel it self has 5000 ticks
        %the encoder interpolates by 400X
        cpr=2000000;
    end
    methods
        function obj=encoder(port,baud)
            global EncoderPort
            %obj=encoder(port,baud)
            %open an encoder object on port using baudrate baud
            %port and baud are optional
            
            %set default baud rate
            if(nargin<2)
                baud=230400;
            end
            %if no port is given look for encoders and use the first one
            if(nargin<1)
                if ~isempty(EncoderPort)
                    port=EncoderPort;
                    serObj=instrfind('Port',port);
                    if ~isempty(serObj)
                        ports=encoder.findEncoders();
                        if isempty(ports)
                            error('Encoder is in use');
                        end
                        port=ports{1};
                        EncoderPort=port;
                    end
                else
                    ports=encoder.findEncoders();
                    if isempty(ports)
                        error('No encoders found');
                    end
                    port=ports{1};
                    EncoderPort=port;
                end
            end

            %initialize serial port with propper baud rate
            obj.ser=serial(port,'BaudRate',baud);
            %open port
            fopen(obj.ser);
            %get the first line from the device
            l=fgetl(obj.ser);
            %make shure that the device name matches the device
            if ~strncmp(obj.devname,l,length(obj.devname))
                fclose(obj.ser);
                delete(obj.ser);
                fprintf('l = %s',l);
                error('Device is not QSB-D');
            end

            %setup bytes availiable callback
            obj.ser.BytesAvailableFcnMode = 'terminator';
            obj.ser.BytesAvailableFcn=@obj.readData;
            
            %set EOR for LC and CR with timestamp and spaces between fields
            obj.send_command('W','15','0F');
            %reset time stamp
            obj.send_command('W','0D','1');
            %reset counter
            obj.send_command('W','09','2');
            %set encoder mode to Quadrature
            obj.send_command('W','00','00');
            %set count mode. enable counting in count up mode with no triggers
            obj.send_command('W','04','00');
            %set opperating modes. X4 quadrature count mode, free running count no
            %index, 
            obj.send_command('W','03','03');
            %set opperating modes. X4 quadrature count mode, free running
            %count synchronous index 
            %obj.send_command('W','03','63');
            %Encoder count threshold. output values at selected rate
            obj.send_command('W','0B','0000');
            %Data Output Interval Rate. 25*1.9ms = 38ms
            %obj.send_command('W','0C','0014');
            obj.send_command('W','0C','0019');      %47.5ms
            %Data Output Interval Rate. 256*1.9ms = 0.5s
            %obj.send_command('W','0C','0100');
        end        
        
        function obj=set.index(obj,ind)
            if ind
                %set opperating modes. X4 quadrature count mode, free running count synchronous index 
                obj.send_command('W','03','63');
            else
                %set count mode. enable counting in count up mode with no triggers
                obj.send_command('W','03','03');
            end
            obj.index=ind;
        end

        function stream(obj)
            %start streaming count values
            obj.send_command('S','0E');
        end

        function send_command(obj,t,r,d)
            %send_command(obj,t,r,d)
            %   send a command to the encoder
            if(nargin<3)
                error('too few arguments');
            elseif nargin <4
                %fprintf('Writing %s',[t,r]);
                fwrite(obj.ser,[t,r,13,10])
            elseif nargin==4
                %fprintf('Writing %s',[t,r,d]);
                fwrite(obj.ser,[t,r,d,13,10])
            end
        end
        
        function delete(obj)
            fprintf(obj.ser,'R0E');
            fclose(obj.ser);
            delete(obj.ser);
        end
    end    
    methods(Static)
        function enc=findEncoders()
            %enc=findEncoders()
            %   Find all encoders that are connected to the computer
            enc={};
            ports=instrhwinfo('serial');
            %turn off warnings when fgetl returns no data
            warning off MATLAB:serial:fgetl:unsuccessfulRead;
            for k=1:length(ports.AvailableSerialPorts)
                %get the constructor for an avalible port
                port=ports.AvailableSerialPorts{k};
                kk=find(strcmp(ports.SerialPorts,port),1);
                %make an inline function for port
                c=inline(ports.ObjectConstructorName{kk},0);
                try
                    %try to open the port
                    s=c(0);
                    %set baud rate
                    set(s,'BaudRate',230400);
                    %set timeout to be short
                    set(s,'Timeout',1);
                    %open port
                    fopen(s);
                    %get the first line from the device
                    %this should be the device name
                    l=fgetl(s);
                    %check if device is correct
                    if strncmp(encoder.devname,l,length(encoder.devname))
                        %this is a QSB-D device, add it to the list
                        enc{end+1}=port;
                    end
                catch err
                    %Don't throw error for failing to open port
                    if(~strcmp(err.identifier,'MATLAB:serial:fopen:opfailed'))
                        rethrow(err)
                    end
                end
                %delete serial object so port is not kept open
                delete(s);
            end
        end
    end
    events
        PositionUpdate
    end
    methods(Access=private,Static)
        function val=toSigned(val)
            %check for negative value
            if(val>((2^(4*8-1))-1))
                val=val-(2^(4*8));
            end
        end
    end
    methods(Access=private)
        %read data from a serial port and update the class
        function readData(obj,ser,~)
            l=fgetl(ser);
            l=l(1:end-1);
            %fprintf(2,'%s',l);
            if strncmp('s 0E',l,4)
                dat=sscanf(l,'s 0E %lx %lx ! ');
                if(length(dat)~=2)
                    fprintf(2,'Error parsing data "%s"\n',l);
                    return
                end
                dat(1)=obj.toSigned(dat(1));
                %set angle
                ang=dat(1)*2*pi/obj.cpr;
                if obj.index
                    %wrap to +/- pi
                    obj.angle=mod(ang+pi,2*pi)-pi;
                else
                    obj.angle=ang;
                end
                %set timestamp
                obj.TimeStamp=dat(2)*obj.dt;
                %check if there is enoughf history to calcualte rates
                if length(obj.A) < 2
                    %initialize history for timestamp and angle
                    obj.T=[obj.A dat(2)*obj.dt];
                    obj.A=[obj.A obj.angle];
                else
                    %update timestamp
                    obj.T=[obj.T(end) obj.TimeStamp];
                    %update angle and unwrap phase
                    obj.A=unwrap([obj.A(end) obj.angle]);
                    %save last rate for acceleration
                    lr=obj.rate;
                    %caluclate rates
                    obj.rate=(obj.A(end)-obj.A(end-1))/(obj.T(end)-obj.T(end-1));
                    %caluclate acceleration
                    if(~isempty(lr))
                        obj.acc=(obj.rate-lr)/(obj.T(end)-obj.T(end-1));
                    end
                    %send event for position update
                    notify(obj,'PositionUpdate');
                end
            elseif isempty(l)
                fprintf(2,'empty response\n');
            elseif l(1)=='w' || l(1)=='r' || l(1)=='e' || l(1)=='x'
                %response to a command
                obj.resp{end+1}=l;
            else
                %unknown response
                fprintf(2,'unknown = \"%s\"\n',l);
            end
        end
    end
    
end

%the following helper functions are used within the class but are not
%avalible externally



