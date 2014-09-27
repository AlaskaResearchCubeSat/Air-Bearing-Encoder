function varargout = airBearing_display(varargin)
% AIRBEARING_DISPLAY GUI for air bearing encoder
%      AIRBEARING_DISPLAY, by itself, creates a new GUI for the encoder or
%      raises the currently running GUI

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @airBearing_display_OpeningFcn, ...
                   'gui_OutputFcn',  @airBearing_display_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before airBearing_display is made visible.
function airBearing_display_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to airBearing_display (see VARARGIN)

if isfield(handles,'enc')
    fprintf('Arrrrrrrrrrrg!!!!!!!!!!!!!\n');
end

% Choose default command line output for airBearing_display
handles.output = hObject;

%type of display 1=angle, 2=rate, 3=angular acceleration
handles.dispType=1;

%set timespan of plot
handles.timeSpan=60;

% Update handles structure
guidata(hObject, handles);

%check if already running
if ~isfield(handles,'enc')
    % This sets up the initial plot
    hp=plot(NaN,NaN,'b');
    %initialize encoder interface
    enc=encoder();
    handles.enc=enc;
    %set initial units to rad
    handles.deg=false;
    %setup event listner
    handles.updateListener=addlistener(handles.enc,'PositionUpdate',@(src,evnt)update_fig(src,evnt,handles,hp,0));
    %start encoder data streaming
    handles.enc.stream();
end
% Update handles structure
guidata(hObject,handles);

% UIWAIT makes airBearing_display wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = airBearing_display_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get plot type
popup_sel_index = get(handles.popupmenu1, 'Value');
handles.dispType=popup_sel_index;
%get timespan
ts=str2double(get(handles.tspanEdit,'String'));
if ts<=0
    ts=Inf;
end
%see if it is rad or deg
if(get(handles.degRadio,'Value')==get(handles.degRadio,'Max'))
	handles.deg=true;
    degUnits='deg';
else
    handles.deg=false;
    degUnits='rad';
end
handles.timeSpan=ts;
%stop listner
delete(handles.updateListener);
%check if we have two axis on one plot
if popup_sel_index==4 || popup_sel_index==5
    %double axis plot
    [ax,h1,h2]=plotyy(NaN,NaN,NaN,NaN);    
    hp=[h1 ax(1);h2 ax(2)];
    %link x-axis together
    linkaxes([ax(1) ax(2)],'x');
    %set automatic ticks so that ticks are updated properly
    set(ax(1), 'YTickMode', 'auto');
    set(ax(2), 'YTickMode', 'auto');
else
    %normal plot
    hp=plot(NaN,NaN,'b');
end
% Update handles structure
guidata(handles.output,handles);
%get time offset
os=handles.enc.TimeStamp;
%setup event listner
handles.updateListener=addlistener(handles.enc,'PositionUpdate',@(src,evnt)update_fig(src,evnt,handles,hp,os));
% Update handles structure
guidata(handles.output,handles);
%set axis lables
switch popup_sel_index
    case 1
        xlabel('Time [sec]');
        ylabel(['Angle [' degUnits ']']);
    case 2
        xlabel('Time [sec]');
        ylabel(['Angular Rate [' degUnits '/sec]']);
    case 3
        xlabel('Time [sec]');
        ylabel(['Angular Acceleration [' degUnits '/sec^2]']);
    case 4
        xlabel('Time [sec]');
        set(get(ax(1),'Ylabel'),'String',['Angle [' degUnits ']']) 
        set(get(ax(2),'Ylabel'),'String',['Angular Rate [' degUnits '/sec]']) 
    case 5
        xlabel('Time [sec]');
        set(get(ax(1),'Ylabel'),'String',['Angle [' degUnits ']']);
        set(get(ax(2),'Ylabel'),'String',['Angular Acceleration [' degUnits '/sec^2]']) 
    %case 6 %polar angle
    %case 7 %polar acceleration
end

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
%get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    handles.enc.index=get(hObject,'Value');


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    delete(handles.enc);
    delete(hObject);

function update_fig(src,evnt,handles,hp,offset)
    %get width of window
    twin=handles.timeSpan;
    %get rad or deg
    if(handles.deg)
        angScl=180/pi;
        angName='deg';
    else
        angScl=1;
        angName='rad';
    end
    set(handles.angTxt,'String',sprintf('Angle = % 3.2f %s',src.angle*angScl,angName));
    set(handles.rateTxt,'String',sprintf('Angular Rate = % 3.2f %s/sec',src.rate*angScl,angName));
    set(handles.accTxt,'String',sprintf('Angular Acceleration = % 3.2f %s/sec^2',src.acc*angScl,angName));
    switch handles.dispType
        case 1  %Angle
            xd=get(hp,'XData');
            yd=get(hp,'YData');
            yd=[yd src.angle*angScl];
            xd=[xd src.TimeStamp-offset];
            idx=xd>(xd(end)-twin);
            yd=yd(idx);
            xd=xd(idx);
            set(hp,'XData',xd);
            set(hp,'YData',yd);
            axis(handles.axis,'tight');
        case 2  %Angular rate
            xd=get(hp,'XData');
            yd=get(hp,'YData');
            yd=[yd src.rate*angScl];
            xd=[xd src.TimeStamp-offset];
            idx=xd>(xd(end)-twin);
            yd=yd(idx);
            xd=xd(idx);
            set(hp,'XData',xd);
            set(hp,'YData',yd);
            axis(handles.axis,'tight');
        case 3  %Angular accel
            xd=get(hp,'XData');
            yd=get(hp,'YData');
            yd=[yd src.acc*angScl];
            xd=[xd src.TimeStamp-offset];
            idx=xd>(xd(end)-twin);
            yd=yd(idx);
            xd=xd(idx);
            set(hp,'XData',xd);
            set(hp,'YData',yd);
            axis(handles.axis,'tight');
        case 4  %Angle + rate
            xd=get(hp(1,1),'XData');
            yd=get(hp(1,1),'YData');
            yd=[yd src.angle*angScl];
            xd=[xd src.TimeStamp-offset];
            idx=xd>(xd(end)-twin);
            yd=yd(idx);
            xd=xd(idx);
            set(hp(1,1),'XData',xd);
            set(hp(1,1),'YData',yd);
            axis(hp(1,2),'tight');
            %rate axis
            xd=get(hp(2,1),'XData');
            yd=get(hp(2,1),'YData');
            yd=[yd src.rate*angScl];
            xd=[xd src.TimeStamp-offset];
            idx=xd>(xd(end)-twin);
            yd=yd(idx);
            xd=xd(idx);
            set(hp(2,1),'XData',xd);
            set(hp(2,1),'YData',yd);
            axis(hp(2,2),'tight');
        case 5  %Angle + accel
            %Angle axis
            xd=get(hp(1,1),'XData');
            yd=get(hp(1,1),'YData');
            yd=[yd src.angle*angScl];
            xd=[xd src.TimeStamp-offset];
            idx=xd>(xd(end)-twin);
            yd=yd(idx);
            xd=xd(idx);
            set(hp(1,1),'XData',xd);
            set(hp(1,1),'YData',yd);
            axis(hp(1,2),'tight');
            %Accel axis
            xd=get(hp(2,1),'XData');
            yd=get(hp(2,1),'YData');
            yd=[yd src.acc*angScl];
            xd=[xd src.TimeStamp-offset];
            idx=xd>(xd(end)-twin);
            yd=yd(idx);
            xd=xd(idx);
            set(hp(2,1),'XData',xd);
            set(hp(2,1),'YData',yd);
            axis(hp(2,2),'tight');
        case 6  %polar angle
            xd=get(hp,'XData');
            yd=get(hp,'YData');
            %translate angle and rate data in polar coordinates to cartisian
            [x,y]=pol2cart(src.angle,src.TimeStamp-offset);
            %add data to arrays
            yd=[yd y];
            xd=[xd x];
            %set axis data
            set(hp,'XData',xd);
            set(hp,'YData',yd);
            %make shure that circles are circles
            axis(handles.axis,'equal');
            set(handles.axis,'PlotBoxAspectRatioMode','auto');
        case 7  %polar acceleration
            xd=get(hp,'XData');
            yd=get(hp,'YData');
            %translate angle and rate data in polar coordinates to cartisian
            [x,y]=pol2cart(src.angle,src.rate*angScl);
            %add data to arrays
            yd=[yd y];
            xd=[xd x];
            %set axis data
            set(hp,'XData',xd);
            set(hp,'YData',yd);
            %make shure that circles are circles
            axis(handles.axis,'equal');
            set(handles.axis,'PlotBoxAspectRatioMode','auto');
    end
    drawnow;
