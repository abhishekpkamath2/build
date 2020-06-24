def file_read(fname):
        content_array = []
        try:
            with open(fname) as f:
                    #Content_list is the list that contains the read lines.
                    for line in f:
                            content_array.append(line)
        except EnvironmentError:
            print('File %s not found'%fname) 
        return content_array

def create_array():
    array = []
    list = file_read(r'filelist.txt')
    for i in list:
        index = i.rfind('/')
        array.append(i[index+1:])
        file_write(r'listfile.txt',array)

def file_write(fname,array):
    try:
        with open(fname, 'w') as filehandle:
            for listitem in array:
                filehandle.write('%s' % listitem)
    except EnvironmentError:
        print('Error while creating File %s'%fname) 


create_array()