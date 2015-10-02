--[[*************************************************************************
*
*	PROJECT:		dxGridlists
*	DEVELOPERS:		t3wz < github.com/t3wz >
*	VERSION:		1.0
*
*	YOU AREN'T ALLOWED TO SELL THIS SCRIPT OR REMOVE THE AUTHOR'S NAME
*					EVEN IF YOU MADE SEVERAL CHANGES !
*
****************************************************************************]]

dxGrid          =   { items = {} };
local cursorOn;

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- Core - functions

function dxGrid:Create ( x, y, width, height, postGUI )
    -- table dxGrid:Create ( int x, int y, int width, int height[, bool postGUI ] )

    if __checkParams ( "Create", "nnnn", x, y, width, height ) then
        local data = {
            x       =       x;                          -- X position
            y       =       y;                          -- Y position
            w       =       width;                      -- Width
            h       =       height;                     -- Height
            pg      =       postGUI or false;           -- PostGUI
            i       =       {};                         -- Items
            mi      =       __calcMaxItems ( height );  -- Max items
            s       =       1;                          -- Scroll Level
            r       =       -1;                         -- Row count
            se      =       -1;                         -- Selected item
            mo      =       nil;                        -- Mouse-on item
            vis     =       true                        -- Visible
        };

        setmetatable ( data, { __index = dxGrid } );
        table.insert ( dxGrid.items, data );

        return data;
    end
end

function dxGrid:Destroy ()
    -- bool dxGrid:Destroy ()

    for k, v in pairs ( dxGrid.items ) do
        if v == self then
            dxGrid.items[k] = nil;
            return true;
        end
    end
    return false;
end

function dxGrid:SetVisible ( visible )
    -- bool Gridlist:SetVisible ( bool state )
    if __checkParams ( "SetVisible", "b", visible ) then
        self.vis = visible

        return true
    else
        return false
    end
end

function dxGrid:IsVisible ( )
    -- bool Gridlist:IsVisible()

    return self.vis
end

function dxGrid:AddColumn ( title, width )
    -- int Gridlist:AddColumn ( string title, int width )

    if __checkParams ( "AddColumn", "sn", title, width ) then
        local data = {
            info    =   { title = title, width = width }
        };

        table.insert ( self.i, data );

        return #self.i;
    end
end

function dxGrid:RemoveColumn ( columnIndex )
    -- bool Gridlist:RemoveColumn ( int columnIndex )

    if __checkParams ( "RemoveColumn", "n", columnIndex ) then
        self.i[columnIndex] = nil;

        -- Recalculate the highest item count
        local highest = -1;

        for _, v in ipairs ( self.i ) do
            if #v > highest then
                highest = ( #v - 1 );
            end
        end

        self.r = highest;

        -- Recalculate the scroll level (if necessary)
        if ( ( ( self.s + self.mi ) - 2 ) == self.r ) then
            self.s = ( self.r - self.mi ) + 1;
        end

        return true
    end
    return false
end

function dxGrid:GetColumnCount ()
    -- int Gridlist:GetColumnCount()

    return #self.i
end

function dxGrid:AddItem ( columnIndex, text, data )
    -- int Gridlist:AddItem ( int columnIndex, string title[, mixed data ] )

    if __checkParams ( "AddItem", "ns", columnIndex, text ) then
        if self.i[columnIndex] then
            table.insert ( self.i[columnIndex], { id = #self.i[columnIndex] + 1, text = tostring( text ), data = data } );

            if #self.i[columnIndex] > self.r then
                self.r = #self.i[columnIndex];
            end

            return #self.i[columnIndex];
        end
        return false;
    end
end

function dxGrid:RemoveItem ( column, itemID )
    -- bool Gridlist:RemoveItem ( int columnIndex, int itemIndex )

    if __checkParams ( "RemoveItem", "nn", column, itemID ) then
        if self.i[column] and self.i[column][itemID] then
            -- Recalculate the highest item count
            if self.r == #self.i[column] then
                local highest = -1;

                for _, v in ipairs ( self.i ) do
                    if #v > highest then
                        highest = ( #v - 1 );
                    end
                end

                self.r = highest;
            end

            -- Recalculate the scroll level (if necessary)
            if ( ( ( self.s + self.mi ) - 2 ) == self.r ) then
                self.s = ( self.r - self.mi ) + 1;
            end

            -- Reset the selected item if necessary²
            if itemID == self.se then
                local newItem   =   self.se - 1

                if newItem <= self.r then
                    self.se = math.max ( 0, newItem );
                else
                    self.se = -1
                end
            end

            table.remove ( self.i[column], itemID );

            return true;
        end
        return false
    end
end

function dxGrid:GetItemCount ( columnID )
    -- int Gridlist:GetItemCount ( int columnIndex )

    if __checkParams ( "GetItemCount", "n", columnID ) then
        if self.i[columnID] then
            return #self.i[columnID]
        end
        return false
    end
end

function dxGrid:Clear ()
    -- bool Gridlist:Clear()

    for k, v in ipairs ( self.i ) do
        self.i[k] = { info = v.info }
    end

    self.r = -1
    self.se = nil

    -- Recalculate the scroll level
    self.s = 1;

    return true
end

function dxGrid:GetSelectedItem ( )
    -- int Gridlist:GetSelectedItem ()

    return self.se;
end

function dxGrid:SetSelectedItem ( itemID )
    -- bool Gridlist:SetSelectedItem ( int itemIndex )

    if __checkParams ( "SetSelectedItem", "n", itemID ) then
        if itemID <= self.r then
            self.se = itemID;
            return self.se == itemID;
        end
        return false;
    end
end

function dxGrid:GetItemDetails ( column, itemID )
    -- string, mixed Gridlist:GetItemDetails ( int columnIndex, int itemIndex )

    if __checkParams ( "GetItemDetails", "nnn", columnID, itemID ) then
        if self.i[column] then
            if self.i[column][itemID] then
                return self.i[column][itemID].text, self.i[column][itemID].data
            end
        end
        return false
    end
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- Core - render/move

addEventHandler ( "onClientRender", root,
    function ( )
        -- Is there any gridlist to render?
        if #dxGrid.items > 0 then
            -- Loop through all grid lists
            for index, data in ipairs ( dxGrid.items ) do
                -- Is the gridlist visible?
                if data.vis then
                    -- Draw the 'gridlist' itself
                    dxDrawRectangle ( data.x, data.y, data.w, data.h, tocolor ( 0, 0, 0, 200 ), data.pg );

                    -- Draw the column bar
                    dxDrawRectangle ( data.x, data.y, data.w, 30 % data.h, tocolor ( 0, 0, 0, 220 ), data.pg );

                    -- Set cursorOn variable to the current gridlist, if it's selected
                    cursorOn = nil
                    if __isMouseInPosition ( data.x, data.y, data.w, data.h ) then
                        cursorOn = index;
                    end

                    -- Check if there's any selected item
                    local seeFrom   =   data.s;
                    local seeTo     =   ( data.s + data.mi ) - 1;

                    if data.se and data.se <= data.r and data.se >= seeFrom and data.se <= seeTo then
                        local index     =   data.se - ( data.s - 1 );
                        local y2        =   data.y + ( ( index - 1 ) * 25 );

                        -- Draw a rectangle to make it looks like selected
                        dxDrawRectangle ( data.x, ( 30 % data.h ) + y2, data.w, 20, tocolor ( 0, 0, 0, 100 ), data.pg );
                    end

                    -- Is there any column?
                    if #data.i > 0 then
    					local cWidth = 0

                        -- Loop through all columns
                        for cIndex, cData in ipairs ( data.i ) do
                            -- we'll go beyond the gridlist width with this column ?
                            if ( ( cWidth + cData.info.width ) <= data.w ) then
                                local x = data.x + cWidth;

                                -- Draw the column title
                                dxDrawText ( cData.info.title, x, data.y, cData.info.width + x, ( 30 % data.h ) + data.y, tocolor ( 255, 255, 255 ), 1, "default-bold", "center", "center", true, true, data.pg, false, true );

                                -- Reset the selected item
                                cData.info.selected = -1;

                                -- Is there any item ?
                                if #cData > 0 then
                                    local seeFrom   =   data.s;
                                    local seeTo     =   ( data.s + data.mi ) - 1;

                                    -- Loop the items
                                    for iIndex = seeFrom, seeTo do
                                        -- There's a row with this index in the current column?
                                        if cData[iIndex] then
                                            local index     =   iIndex - ( data.s - 1 );
                                            local y         =   data.y + ( index * 25 );
                                            local y2        =   data.y + ( ( index - 1 ) * 25 );

                                            -- Check if cursor is on item position
                                            if __isMouseInPosition ( data.x, ( 30 % data.h ) + y2, data.w, 20 ) then
                                                -- Define the mouse-on variable
                                                data.mo = iIndex;
                                            end

                                            -- Draw the item text
                                            dxDrawText ( cData[iIndex]["text"], x, y, cData.info.width + x, ( 30 % data.h ) + y, tocolor ( 255, 255, 255 ), 1, "default-bold", "center", "center", true, true, data.pg, false, true );
                                        end
                                    end
                                end

                                -- Increase cWidth variable (to draw the columns correctly)
                                cWidth = cWidth + cData.info.width;
                            end
                        end
                    end
                end
            end
        end
    end
, true, "low-5")

--

addEventHandler ( "onClientKey", root,
    function ( button, press )
        -- Is cursor showing?
        if isCursorShowing () then
            -- Is there any gridlist?
            if #dxGrid.items > 0 then
                -- Is there any selected gridlist?
                if cursorOn then
                    -- We pressed the scroll?
                    if press and #button > 6 then
                        -- Does the gridlist requires scroll?
                        if dxGrid.items[cursorOn].r > dxGrid.items[cursorOn].mi then
                            -- Define some variables
                            local index         =   cursorOn;
                            local currentValue  =   dxGrid.items[index].s;
                            local newValue      =   math.max ( 1, button == "mouse_wheel_down" and currentValue + 2 or currentValue -1 );

                            -- Check if we have spent the row's limit with the new value
                            if ( ( newValue + dxGrid.items[index].mi ) > dxGrid.items[index].r ) then
                                newValue = ( dxGrid.items[index].r - dxGrid.items[index].mi ) + 1;
                            end

                            -- Set the new scroll level
                            dxGrid.items[index].s = newValue;
                        end
                    elseif press and button == "mouse1" and dxGrid.items[cursorOn].mo then
                        dxGrid.items[cursorOn].se = dxGrid.items[cursorOn].mo;
                    end
                end
            end
        end
    end
)

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- Useful

function __calcMaxItems ( height )
    for i = 0, 9999 do
        if ( ( ( i + 1 ) * 25 ) >= height ) then
            return i;
        end
    end
    return false;
end

function __checkParams ( methodName, pattern, ... )
    local cTable = {
        ["string"] = "s";
        ["number"] = "n";
        ["boolean"] = "b";

        ["s"] = "string";
        ["n"] = "number";
        ["b"] = "boolean"
    };

    if #pattern > table.maxn ( { ... } ) then
        local index = table.maxn ( { ... } ) == 0 and 1 or table.maxn ( { ... } ) + 1
        return false, error ( "Bad Argument @ '"..methodName.."' [Expected "..cTable[ pattern:sub ( index, index ) ].." at argument "..index..", got none]" )
    end

    for k, v in pairs ( { ... } ) do
        if cTable[ type ( v ) ] ~= pattern:sub ( k, k ) then
            return false, error ( "Bad Argument @ '"..methodName.."' [Expected "..cTable[ pattern:sub ( k, k ) ].." at argument "..k..", got "..( type ( v ) or "none" ).."]" )
        end
    end
    return true;
end

function __isMouseInPosition ( x, y, w, h )
    if not isCursorShowing() then return false end

    local res   =   { guiGetScreenSize() };
    local cpos  =   { getCursorPosition() };
    local fpos  =   { res[1] * cpos[1], res[2] * cpos[2] };
    return ( fpos[1] >= x and fpos[1] <= x + w ) and ( fpos[2] >= y and fpos[2] <= y + h )
end
