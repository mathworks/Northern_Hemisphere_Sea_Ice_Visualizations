classdef iceConcentrationApp < matlab.apps.AppBase
   
% Copyright 2020 The MathWorks, Inc.
% @Authors: Shubo Chakrabarti, Kelly Luetkemeyer
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        Axes               matlab.graphics.axis.Axes
        Label              matlab.ui.control.Label
        YearsListBoxLabel  matlab.ui.control.Label
        YearsListBox       matlab.ui.control.ListBox
    end
    
    
    properties (Access = private)
        file       % filename of current file
        axeshandle % Description
        startfile  % First file for template
        Cache
        CurrentYear
        Colormap
    end
    
    methods (Access = private)
        
        function makemap(app,~)
            ice_concentration = app.Cache.("Year_" + app.CurrentYear).IceConcentration;
            copyright = app.Cache.("Year_" + app.CurrentYear).Copyright;
            year = extractBetween(copyright," "," ");
            copyright = replaceBetween(copyright," "," ","(" + year + ")");
            copyright = replace(copyright, "Copyright", "Copyright ©");
            ax = app.Axes;
            h = findall(ax,'type','surface');
            set(h,'ZData', ice_concentration,'CData', ice_concentration);
            app.Label.Text = [ ...
                "Ice Concentration : December " +  app.CurrentYear; ...
                string(copyright)];
        end
    end
    
    
    % Callbacks that handle component events
    methods (Access = private)
        
        % Code that executes after component creation
        function AppStartupFcn(app)
            
            % extract concentration file names
            files = struct2table(dir('data/*'));
            files = files.name(contains(files.name,'conc'));
            files = string(files(contains(files,'.nc4')));
            
            % build filename
            app.file = fullfile(pwd,'data',files(1));
            app.startfile = app.file;
            
            % extract years & update menu
            cachefile = fullfile(pwd,'data',"ice_conc_cache.mat");
            app.Cache = load(cachefile);
            years = string(extractAfter(fieldnames(app.Cache),"Year_"));
            app.YearsListBox.Items = years;
            
            % Initialize map.
            app.CurrentYear = years(1);
            initializeMap(app)
        end
        
        function initializeMap(app)
            ice_concentration = ncread(app.file,'ice_conc');
            land = shaperead('landareas','UseGeoCoords',true);
            
            lat = ncread(app.file,'lat');
            lon = ncread(app.file,'lon');
            latlim = [min(lat(:)) max(lat(:))];
            
            % draw map axis
            gcolor = [1 1 1];
            levels = 0:5:100;
            tempFigure = figure('Colormap',app.Colormap);
            mapaxes = axesm('eqaazim','Origin',[90 0 0],'MapLatLimit',double(latlim), ...
                'Grid','on','GColor',gcolor);
            caxis(mapaxes,[min(levels) max(levels)]);
            
            geoshow(lat,lon,ice_concentration,'DisplayType','surface')
            landcolor = [204 204 204]/255;
            geoshow(land,'FaceColor',landcolor)
            
            h = colorbar(mapaxes);
            h.Label.String = 'ice concentration percentage (0:100)';
            h.Ticks = levels;
            
            axis(mapaxes,'off')
            nlim = .82;
            set(mapaxes,'XLim',[-nlim,nlim],'YLim',[-nlim,nlim])
                        
            % place axes in app parent and delete original axes
            mapaxes.Parent = app.Axes.Parent;
            mapaxes.Units = 'pixel';
            mapaxes.Position = app.Axes.Position;
            
            % delete the initial Axes
            delete(app.Axes);
            app.Axes = mapaxes;
            
            % delete the map figure
            delete(tempFigure);
                        
            % update the label
            names = string(fieldnames(app.Cache));
            copyright = app.Cache.(names(1)).Copyright;
            year = extractBetween(copyright," "," ");
            copyright = replaceBetween(copyright," "," ","(" + year + ")");
            copyright = replace(copyright, "Copyright", "Copyright ©");
            app.Label.Text = [ ...
                "Ice Concentration : December " +  app.CurrentYear; copyright];
        end
        
        % Value changed function: YearsListBox
        function yearSelected(app, ~)
            value = app.YearsListBox.Value;
            app.CurrentYear = value;
            makemap(app,1)
        end
    end
    
    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            S = load(fullfile(pwd,'data','ice_colormap'));
            ice_colormap = S.ice_colormap;
            app.Colormap = ice_colormap;

            % Create UIFigure and hide until all components are created            
            app.UIFigure = uifigure('Visible', 'off','Colormap',app.Colormap);
            app.UIFigure.Color = [0.94 0.94 0.94];
            app.UIFigure.Position = [100 100 905 676];
            app.UIFigure.Name = 'Ice Concentration App';
            
            % Create Axes
            app.Axes = axes(app.UIFigure);
            title(app.Axes, '')
            xlabel(app.Axes, '')
            ylabel(app.Axes, '')
            app.Axes.XTick = [];
            app.Axes.YTick = [];
            app.Axes.Position = [83 72 640 553];
            
            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.FontWeight = 'bold';
            app.Label.Position = [272 635 299 30];
            
            % Create YearsListBoxLabel
            app.YearsListBoxLabel = uilabel(app.UIFigure);
            app.YearsListBoxLabel.HorizontalAlignment = 'right';
            app.YearsListBoxLabel.FontWeight = 'bold';
            app.YearsListBoxLabel.Position = [780 618 38 22];
            app.YearsListBoxLabel.Text = 'Years';
            
            % Create YearsListBox
            app.YearsListBox = uilistbox(app.UIFigure);
            app.YearsListBox.ValueChangedFcn = createCallbackFcn(app, @yearSelected, true);
            app.YearsListBox.Position = [749 93 100 511];
            
        end
    end
    
    % App creation and deletion
    methods (Access = public)
        
        % Construct app
        function app = iceConcentrationApp
            
            % Create UIFigure and components
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            % Execute the startup function
            runStartupFcn(app, @AppStartupFcn)
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            
            if nargout == 0
                clear app
            end
        end
        
        % Code that executes before app deletion
        function delete(app)
            
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
