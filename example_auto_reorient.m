function example_auto_reorient(rootpath)
% example_auto_reorient(rootpath)
% Simple example script that reorients all files found in a folder
    cd(rootpath)
    fileslist = ls(rootpath)
    fileslist = fileslist(3:end, :)  % remove '.' and '..' from the list
    spm_auto_reorient(fileslist)
end %endfunction