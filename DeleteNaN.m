function RecordedAngles = DeleteNaN(vector)
    RecordedAngles = [];
    
    for i = 1:numel(vector)
        if ~isnan(vector(i))
            RecordedAngles = [RecordedAngles, vector(i)];
        
        elseif isnan(vector(i))
            break
            
        end
        
    end