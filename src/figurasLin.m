classdef figurasLin
    % figurasLin auto-generated (File > Generate Code) plotting helpers
    % for the monitor-camera response linearization figures (see
    % UtilFunFPA.LinLUTGV) - each method reproduces one specific
    % annotated plot, not general-purpose plotting utilities
    methods (Static)
        function figura_Hu_Lu(X1, Y1, X2, Y2)
            % figura_Hu_Lu plots the measured response H(u) and its
            % linearized target L(u) between (u0,v0) and (u1,v1)
            %  X1/Y1: H(u) data; X2/Y2: L(u0:u1) data

            % Create figure
            figure1 = figure;

            % Create axes
            axes1 = axes('Parent',figure1);
            hold(axes1,'on');

            % Create plot
            plot(X1,Y1,'DisplayName','H(u) medida');

            % Create plot
            plot(X2,Y2,'DisplayName','L(u0:u1)');

            % Create ylabel
            ylabel('v','FontWeight','bold','FontName','Times New Roman');

            % Create xlabel
            xlabel('u','FontWeight','bold','FontName','Times New Roman');

            % Create title
            title({'Linearización respuesta monitor - cámara'});

            % Uncomment the following line to preserve the X-limits of the axes
             xlim(axes1,[0 255]);
            % Uncomment the following line to preserve the Y-limits of the axes
             ylim(axes1,[0 256]);
            box(axes1,'on');
            hold(axes1,'off');
            % Set the remaining axes properties
            set(axes1,'FontName','Times New Roman','FontSize',12,'FontWeight','bold',...
                'XGrid','on','YGrid','on');
            % Create legend
            legend1 = legend(axes1,'show');
            set(legend1,...
                'Position',[0.144746206669422 0.751269838408819 0.231071431909289 0.131904764765785]);

            % Create arrow
            annotation(figure1,'arrow',[0.762127976190476 0.744419642857143],...
                [0.804598290598291 0.850470085470086]);

            % Create textbox
            annotation(figure1,'textbox',...
                [0.712857142857141 0.740952380952382 0.125714285714286 0.0596764346764381],...
                'String',{'B (u_1, v_1)'},...
                'FontName','Cambria Math',...
                'FitBoxToText','off',...
                'BackgroundColor',[0.631372549019608 0.866666666666667 0.968627450980392]);

            % Create arrow
            annotation(figure1,'arrow',[0.166651785714286 0.160401785714286],...
                [0.215952380952381 0.161465201465202]);

            % Create textbox
            annotation(figure1,'textbox',...
                [0.137331845238094 0.224761904761906 0.129811011904763 0.0590476190476196],...
                'String','A (u_0, v_0)',...
                'FontName','Cambria Math',...
                'FitBoxToText','off',...
                'BackgroundColor',[0.631372549019608 0.866666666666667 0.968627450980392]);
        end

        function figura_Tu(X1, Y1, X2, Y2)
            % figura_Tu plots the linearization LUT T(u)=H^-1[L(u)],
            % with the interior [u0,u1] samples marked
            %  X1/Y1: full T(u) data; X2/Y2: T(u0:u1) marker data

            % Create figure
            figure1 = figure;

            % Create axes
            axes1 = axes('Parent',figure1);
            hold(axes1,'on');

            % Create plot
            plot(X1,Y1,'DisplayName','T(u)');

            % Create plot
            plot(X2,Y2,'DisplayName','T(u0:u1)','Marker','+','LineStyle','none');

            % Create ylabel
            ylabel('T(u)','FontWeight','bold','FontName','Times New Roman');

            % Create xlabel
            xlabel('u','FontWeight','bold','FontName','Times New Roman');

            % Create title
            title({'Transformación u'' = T(u) = H^-^1[L(u)]'});

            % Uncomment the following line to preserve the X-limits of the axes
            xlim(axes1,[0 256]);
            % Uncomment the following line to preserve the Y-limits of the axes
            ylim(axes1,[0 255]);
            box(axes1,'on');
            hold(axes1,'off');
            % Set the remaining axes properties
            set(axes1,'FontName','Times New Roman','FontSize',12,'FontWeight','bold',...
                'XGrid','on','YGrid','on');
            % Create legend
            legend1 = legend(axes1,'show');
            set(legend1,...
                'Position',[0.155015808660664 0.751269838408819 0.189642859492983 0.131904764765785]);

            % Create arrow
            annotation(figure1,'arrow',[0.759270833333332 0.741562499999999],...
                [0.699836385836387 0.745708180708182]);

            % Create textbox
            annotation(figure1,'textbox',...
                [0.73947470238095 0.633333333333338 0.0433824404761923 0.0590476190476195],...
                'String','u_1',...
                'FontName','Cambria Math',...
                'FitBoxToText','off',...
                'BackgroundColor',[0.631372549019608 0.866666666666667 0.968627450980392]);

            % Create arrow
            annotation(figure1,'arrow',[0.214285714285714 0.172276785714286],...
                [0.156190476190477 0.144755799755801]);

            % Create textbox
            annotation(figure1,'textbox',...
                [0.224474702380949 0.137142857142862 0.0433824404761923 0.0590476190476197],...
                'String','u_0',...
                'FontName','Cambria Math',...
                'FitBoxToText','off',...
                'BackgroundColor',[0.631372549019608 0.866666666666667 0.968627450980392]);
        end
        function figura_Hufin(X1, Y1, X2, Y2)
            % figura_Hufin plots the final linearized response
            % H(T(u))=L(u), with the interior [u0,u1] samples marked
            %  X1/Y1: full H(T(u)) data; X2/Y2: H(T(u0:u1)) marker data

            % Create figure
            figure1 = figure;

            % Create axes
            axes1 = axes('Parent',figure1);
            hold(axes1,'on');

            % Create plot
            plot(X1,Y1,'DisplayName','H(T(u))');

            % Create plot
            plot(X2,Y2,'DisplayName','H(T(u0:u1)','Marker','+','LineStyle','none');

            % Create ylabel
            ylabel('H(T(u))','FontWeight','bold','FontName','Times New Roman');

            % Create xlabel
            xlabel('u','FontWeight','bold','FontName','Times New Roman');

            % Create title
            title({'Respuesta lineal v'' = H(u'') = L(u)'});

            % Uncomment the following line to preserve the X-limits of the axes
            xlim(axes1,[0 255]);
            % Uncomment the following line to preserve the Y-limits of the axes
            ylim(axes1,[0 256]);
            box(axes1,'on');
            hold(axes1,'off');
            % Set the remaining axes properties
            set(axes1,'FontName','Times New Roman','FontSize',12,'FontWeight','bold',...
                'XGrid','on','YGrid','on');
            % Create legend
            legend1 = legend(axes1,'show');
            set(legend1,...
                'Position',[0.144746206669422 0.751269838408819 0.231071431909289 0.131904764765785]);

            % Create arrow
            annotation(figure1,'arrow',[0.762127976190476 0.744419642857143],...
                [0.804598290598291 0.850470085470086]);

            % Create textbox
            annotation(figure1,'textbox',...
                [0.712857142857141 0.740952380952382 0.125714285714286 0.0596764346764381],...
                'String',{'B (u_1, v_1)'},...
                'FontName','Cambria Math',...
                'FitBoxToText','off',...
                'BackgroundColor',[0.631372549019608 0.866666666666667 0.968627450980392]);

            % Create arrow
            annotation(figure1,'arrow',[0.166651785714286 0.160401785714286],...
                [0.215952380952381 0.161465201465202]);

            % Create textbox
            annotation(figure1,'textbox',...
                [0.137331845238094 0.224761904761906 0.129811011904763 0.0590476190476196],...
                'String','A (u_0, v_0)',...
                'FontName','Cambria Math',...
                'FitBoxToText','off',...
                'BackgroundColor',[0.631372549019608 0.866666666666667 0.968627450980392]);

        end
    end
end
