#!/bin/bash

################################################################################
################################################################################
#    subotage - universal subtitle converter
#    Copyright (C) 2010  Tomasz Wisniewski <tomasz@wisni3wski@gmail.com>

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
################################################################################

g_InputFrameRate="23.98"
g_OutputFrameRate="23.98"
g_InFpsGiven=0

g_InputFormat="none"
g_OutputFormat="subrip"
g_FormatDetected=0

g_InputFile="none"
g_OutputFile="none"
g_LastingTime="3000"

g_ProcessId=$$
g_ProcTmpFile="/tmp/subotage_${g_ProcessId}.tmp"
g_LineCounter=0
g_Quiet=0

# current version
g_Version="0.16 alpha"

# supported subtitle file formats
g_FileFormats=( "microdvd" "mpl2" "subrip" "tmplayer" "subviewer" "fab" )

# description for every supported file format
g_FormatDescription=( "Format based on frames. Uses given framerate\n\t\t(default is [$g_InputFrameRate] fps)"
                      "[start][stop] format. The unit is time based == 0.1 sec"
                      "hh.mm.ss,mmm -> hh.mm.ss,mmm format"
                      "hh:mm:ss timestamp format without the\n\t\tstop time information. Mostly deprecated"
                      "hh:mm:ss:dd,hh:mm:ss:dd format with header.\n\t\tResolution = 10ms. Header is ignored"
                      "similar to subviewer, subrip.\n\t\t0022 : 00:05:22:01  00:05:23:50. No header"
                    ) 


################################################################################
########################## format detection routines ###########################
################################################################################
# each detection function should return a string delimited by spaces containing:
# - format name (as in g_FileFormats table) or "not detedted" string
#       if file has not been identified
# - line in file on which a valid format line has been found (starting from 1)
# - format specific data
################################################################################

# fab format detection routine
function f_is_fab_format
{
    max_attempts=8
    attempts=$max_attempts
    match="not detected"
    first_line=1
    
    while read file_line; do
        if [[ $attempts -eq 0 ]]; then
            break
        fi
        
        first_line=$(( $max_attempts - $attempts + 1))  
        cnti=$(echo $file_line | sed -r 's/^[0-9]+ : [0-9]+:[0-9]+:[0-9]+:[0-9]+[ ]+[0-9]+:[0-9]+:[0-9]+:[0-9]+[\r\n]*$/success/')
        
        if [[ $cnti = "success" ]]; then
            match="fab $first_line"
            break
        fi  
        
        attempts=$(( $attempts - 1 ))       
    done < "$1"
        
    echo $match         
}

# subviewer format detection routine
function f_is_subviewer_format
{
    max_attempts=16
    attempts=$max_attempts
    match="not detected"
    first_line=0
    
    header_found=0

    while read file_line; do
        if [[ $attempts -eq 0 ]]; then
            break
        fi
        
        first_line=$(( $first_line + 1 ))
        
        if [[ $header_found -eq 1 ]]; then
            match_line=$(echo $file_line | sed -r 's/^[0-9]+:[0-9]+:[0-9]+:[0-9]+,[0-9]+:[0-9]+:[0-9]+:[0-9]+[ \r]*$/success/')
            
            if [[ $match_line = "success" ]]; then
                first_line=$(( $first_line - 1 ))
                match="subviewer $first_line"
                break
            fi          
        fi
                
        if [[ -n $(echo $file_line | grep "\[INFORMATION\]") ]]; then
            header_found=1
            continue
        fi
                
        attempts=$(( $attempts - 1 ))       
    done < "$1"
        
    echo $match 
}


# tmplayer format detection routine
function f_is_tmplayer_format
{
    max_attempts=3
    attempts=$max_attempts
    match="not detected"
    first_line=1
    
    multiline="no"
    hour_digits=2
    delimiter=":"
    
    while read file_line; do
        if [[ $attempts -eq 0 ]]; then
            break
        fi
        
        first_line=$(( $max_attempts - $attempts + 1))
        
        # the check itself
        match_value=$(echo "$file_line" | sed -r 's/^[0-9]+:[0-9]+:[0-9]+/success/')
        
        # tmplayer format detected. Get more details
        if [[ -n $(echo "$match_value" | grep "success") ]]; then
                
            hour_digits=$(echo "$file_line" | awk 'BEGIN { FS=":"; } { printf ("%d", length($1)); }')
            mline=$(echo "$file_line" | sed -r 's/^[0-9]+:[0-9]+:[0-9]+,[0-9]+/success/')
            
            if [[ -n $(echo "$mline" | grep "success") ]]; then
                multiline="yes"
                
                # determine the time, text delimiter type           
                delimiter=$(echo "$mline" | sed 's/^success\(.\).*/\1/')
            else
                delimiter=$(echo "$match_value" | sed 's/^success\(.\).*/\1/')
            fi
            
            match="tmplayer $first_line $hour_digits $multiline [$delimiter]"
            break
        fi 

        attempts=$(( $attempts - 1 ))       
    done < "$1"
        
    echo $match
}

# microdvd format detection routine
function f_is_microdvd_format
{
    max_attempts=3
    attempts=$max_attempts
    match="not detected"
    first_line=1

    while read file_line; do
        if [[ $attempts -eq 0 ]]; then
            break
        fi

        first_line=$(( $max_attempts - $attempts + 1))
        
        match_value=$(echo $file_line | cut -d '}' -f -2 | sed 's/^{[0-9]*}{[0-9]*$/success/')      

        # it is microdvd format, try to determine the frame rate from the first line
        if [[ $match_value = "success" ]]; then
            match="microdvd $first_line"
            fps_info=$(head -n 1 "$1" | cut -d '}' -f 3-)
            fps=0
            
            if [[ -n $(echo $fps_info | awk '/^[0-9]+[\.0-9]*[\r\n]*$/') ]] 
            then
                fps=$(echo $fps_info | tr -d '\r\n')
            fi

            break   
        fi
        
        attempts=$(( $attempts - 1 ))       
    done < "$1"

    if [[ -z $fps ]]; then
        echo "$match"
    else
        echo "$match $fps"
    fi
}

# mpl2 format detection routine
function f_is_mpl2_format
{
    max_attempts=3
    attempts=$max_attempts
    match="not detected"
    first_line=1    

    while read file_line; do
        if [[ $attempts -eq 0 ]]; then
            break
        fi
        
        first_line=$(( $max_attempts - $attempts + 1))

        match_value=$(echo $file_line | cut -d ']' -f -2 | sed 's/^\[[0-9]*\]\[[0-9]*$/success/')       

        # mpl2 format detected
        if [[ $match_value = "success" ]]; then
            match="mpl2 $first_line"
            break   
        fi
        
        attempts=$(( $attempts - 1 ))       
    done < "$1"

    echo "$match"
}


# subrip format detection routine
function f_is_subrip_format
{
    match="not detected"
    max_attempts=8
    attempts=$max_attempts
    counter_type="not found"
    first_line=1

    while read file_line; do
        if [[ $attempts -eq 0 ]]; then
            break
        fi

        if [[ $counter_type = "not found" ]]; then      
            cntn=$(echo $file_line | awk '/^[0-9]+[\r\n]*$/')
            first_line=$(( $max_attempts - $attempts + 1))

            if [[ -n $cntn ]]; then
                counter_type="newline"              
                continue
            fi
            
            cnti=$(echo $file_line | sed -r 's/^[0-9]+ [0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+[\r\n]*$/success/')

            if [[ $cnti = "success" ]]; then
                counter_type="inline"
                match="subrip $first_line inline"
                break
            fi          
        elif [[ $counter_type = "newline" ]]; then
            
            time_check=$(echo $file_line | sed -r 's/^[0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+[\r\n]*$/success/')

            if [[ $time_check = "success" ]]; then
                match="subrip $first_line newline"
                break
            else
                counter_type="not found"
            fi                          
        fi
                    
        attempts=$(( $attempts - 1 ))       
    done < "$1" 
    
    echo $match 
}

###############################################################################
########################## format detection routines ##########################
###############################################################################




###############################################################################
############################ format read routines #############################
###############################################################################
# Input parameters
# - filename to process
#
# Output: 
# - should be written in universal format. Line format
# - subtitle line number
# - time type: ( "hms", "hmsms", "secs" )
# - start time
# - stop time
# - line itself
#
# Return Value
# - 0 - when file is processed and all the data is converted to 
#             universal format present in /tmp file
###############################################################################

# subviewer -> uni format converter
function f_read_subviewer_format
{
    echo "secs" > "$g_ProcTmpFile"

    tail -n +"$2" "$1" | tr -d '\r' | 
    awk "BEGIN { 
		FS=\"\n\"; RS=\"\"; linecc=1; 
		};
        {   split(\$1, start, \",\");
            split(start[1], tm_start, \":\");
            split(start[2], tm_stop, \":\");
            time_start=(tm_start[1]*3600 + tm_start[2]*60 + tm_start[3] + tm_start[4]/100)
            time_stop=(tm_stop[1]*3600 + tm_stop[2]*60 + tm_stop[3] + tm_stop[4]/100)       
            printf(\"%d %s %s \", linecc, time_start, time_stop);           
            for (i=2; i<=NF; i++) {
                if (i>2) printf(\"|\");
                printf(\"%s\", \$i);                        
            }
            printf(\"\n\");
            linecc=linecc + 1;
        }" >> "$g_ProcTmpFile"
        
    echo 0  
}

# tmplayer -> uni format converter
function f_read_tmplayer_format
{
    multiline="no"
    hour_digits=2
    delimiter=":"
    
    # format information based on autodetection
    if [[ ${#g_InputFormatData[*]} -gt 3 ]]; then
        
        hour_digits="${g_InputFormatData[2]}"
        multiline="${g_InputFormatData[3]}"
        delimiter="$(echo ${g_InputFormatData[4]} | tr -d '[]')"
    fi
    
    echo "hms" > $g_ProcTmpFile
    
    if [[ $multiline = "no" ]]; then
    
        if [[ $delimiter = ":" ]]; then
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { 
						FS=\"$delimiter\";
						line_processed = 1;
					}; 
					/^ *$/ {
						next;
					};
					length { 
						x=(\$1*3600+\$2*60+\$3 + ($g_LastingTime/1000));
						printf(\"%d %02d:%02d:%02d %02d:%02d:%02d \", line_processed++, 
							\$1,\$2,\$3,
							(x/3600), ((x/60)%60), (x%60));

						for (i=4; i<=NF; i++) 
							printf(\"%s\", \$i);
						printf \"\n\"; 
					}" >> "$g_ProcTmpFile"      
        else
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { FS=\"$delimiter\" }; 
                {                   
                    split(\$1, st, \":\");
                    x=((st[1]*3600)+(st[2]*60)+st[3]) + ($g_LastingTime/1000);
                    printf(\"%d %s %02d:%02d:%02d \", NR, 
                    \$1,
                    (x/3600), ((x/60)%60), (x%60));
                    for (i=2; i<=NF; i++) printf(\"%s\", \$i);
                    printf \"\n\"; 
                }" >> "$g_ProcTmpFile"                  
        fi  
    else
        if [[ $delimiter = ":" ]]; then
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { FS=\"$delimiter\"; xprev=0; linecc=1; }; 
                {                   
                    split(\$3, st, \",\");
                    xc=(\$1*3600+\$2*60+st[1]);
                    xe=xc+($g_LastingTime/1000);
                    if (xc == xprev && NR>1) {
                        printf(\"|\");                      
                    } else
                    {
                        if (NR>1) {
                            printf \"\n\";
                            linecc=linecc+1;
                        }                                               
                        printf(\"%d %02d:%02d:%02d %02d:%02d:%02d \", linecc, 
                            \$1,\$2,\$3,
                            (xe/3600), ((xe/60)%60), (xe%60));
                    }                       
                    for (i=4; i<=NF; i++) printf(\"%s\", \$i);
                    xprev=xc;           
                }" >> "$g_ProcTmpFile"
        else
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { FS=\"$delimiter\"; xprev=0; linecc=1; }; 
                {                   
                    split(\$1, st, \"[:,]\");
                    xc=((st[1]*3600)+(st[2]*60)+st[3]);
                    xe=xc+($g_LastingTime/1000);                    
                    if (xc == xprev && NR>1) {
                        printf(\"|\");                      
                    } else
                    {
                        if (NR>1) {
                            printf \"\n\";
                            linecc=linecc+1;
                        }                                               
                        printf(\"%d %02d:%02d:%02d %02d:%02d:%02d \", linecc, 
                            (xc/3600), ((xc/60)%60), (xc%60),
                            (xe/3600), ((xe/60)%60), (xe%60));                       
                    }                       
                    for (i=2; i<=NF; i++) printf(\"%s\", \$i);
                    xprev=xc;           
                }" >> "$g_ProcTmpFile"
        fi
    fi
    
    echo 0
}

# microdvd -> uni format converter
function f_read_microdvd_format
{   
    echo "secs" > $g_ProcTmpFile
    tail -n +"$2" "$1" | tr -d '\r' | 
        awk "BEGIN { 
				FS=\"[{}]+\";
				txt_begin = 0;
				line_processed = 1;
			}; 
			/^ *$/ {
				next;
			}
			{
				fstart=\$2;
				if (\$3+0) {
					txt_begin=4;
					fend=\$3;
				}
				else {
					txt_begin=3;
					fend = \$2 + 5*$g_InputFrameRate;
				}

			   	printf \"%s %s %s \", line_processed++, 
					(fstart/$g_InputFrameRate), (fend/$g_InputFrameRate);

            	for (i=txt_begin; i<=NF; i++) 
					printf(\"%s\", \$i);
				printf \"\n\"; 
			}" >> "$g_ProcTmpFile"
    echo 0
}

# mpl2 -> uni format converter
function f_read_mpl2_format
{
    echo "secs" > $g_ProcTmpFile
    tail -n +"$2" "$1" | tr -d '\r' | 
        awk "BEGIN { 
				FS=\"[][]+\";
				line_processed = 1;
			}; 
			/^ *$/ {
				next;
			}
			length { 
				printf \"%s %s %s \", line_processed++, (\$2/10), (\$3/10);
				for (i=4; i<=NF; i++) printf(\"%s\", \$i);
				printf \"\n\"; 
			}" >> "$g_ProcTmpFile"
    echo 0
}

# subrip -> uni format converter
function f_read_subrip_format
{
    echo "hmsms" > $g_ProcTmpFile
    
    if [[ "$3" == "inline" ]]; then
    
        tail -n +"$2" "$1" | tr -d '\r' | 
            awk "BEGIN { 
					FS=\"\n\"; 
					RS=\"\"; 
				};
                length {  
					gsub(\",\", \".\", \$1);
                    printf(\"%s \", \$1);
                    for (i=2; i<=NF; i++) {
                        if (i>2) printf(\"|\");
                        printf(\"%s\", \$i);                        
                    }
                    printf(\"\n\");
                }" | sed 's/--> //' >> "$g_ProcTmpFile"
                
    else
        # assume newline style      
        tail -n +"$2" "$1" | tr -d '\r' | 
            awk "BEGIN { FS=\"\n\"; RS=\"\"; };
                {   gsub(\",\", \".\", \$2);
                    printf(\"%s %s \", \$1, \$2);
                    for (i=3; i<=NF; i++) {
                        if (i>3) printf(\"|\");
                        printf(\"%s\", \$i);                        
                    }
                    printf(\"\n\");
                }" | sed 's/--> //' >> "$g_ProcTmpFile"                 
    fi
    
    echo 0
}


# fab -> uni format converter
function f_read_fab_format
{
    echo "hmsms" > $g_ProcTmpFile
    
    tail -n +"$2" "$1" | tr -d '\r' | 
        awk "BEGIN { FS=\"\n\"; RS=\"\"; };
            {   
                split(\$1,tm, \":\");
                split(tm[5],tm2, \" \");
                printf(\"%d %02d:%02d:%02d.%02d %02d:%02d:%02d.%02d \", 
                    tm[1], tm[2], tm[3], tm[4], tm2[1],
                    tm2[2], tm[6], tm[7], tm[8]);
                                        
                for (i=2; i<=NF; i++) {
                    if (i>2) printf(\"|\");
                    printf(\"%s\", \$i);                        
                }
                printf(\"\n\");
            }" >> "$g_ProcTmpFile"
                
    echo 0
}

###############################################################################
############################ format read routines #############################
###############################################################################






###############################################################################
############################ format write routines ############################
###############################################################################

# uni -> microdvd format converter
function f_write_microdvd_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs") 
    tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
    awk "{ printf \"{%d}{%d}\", (\$2*$g_OutputFrameRate),(\$3*$g_OutputFrameRate);
            for (i=4; i<=NF; i++) printf(\"%s \", \$i); \
            printf \"\n\" }" > "$1"
    ;;
    
    "hmsms" | "hms")
    tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");                    
            printf(\"{%d}{%d}\", 
             ((start[1]*3600 + start[2]*60 + start[3])*$g_OutputFrameRate),
             ((stop[1]*3600 + stop[2]*60 + stop[3])*$g_OutputFrameRate));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\" }" > "$1" 
    ;;
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


# uni -> tmplayer format converter
function f_write_tmplayer_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs")
        tail -n +2  "$g_ProcTmpFile" | tr -d '\r' |
        awk "{ 
				printf(\"%02d:%02d:%02d:\", 
					(\$2/3600),((\$2/60)%60),(\$2%60));
				for (i=4; i<=NF; i++) printf(\"%s \", \$i);
				printf \"\n\";
			}" > "$1" 
    ;;
    
    "hms" | "hmsms")
        tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
        awk "{ printf (\"%s:\", 
                substr(\$2, 0, index(\$2, \".\")));
                for (i=4; i<=NF; i++) printf(\"%s \", \$i); \
                printf \"\n\" }" > "$1" 
    ;;
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


# uni -> subviewer format converter
function f_write_subviewer_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    echo    "[INFORMATION]" > "$1"  
    echo    "[TITLE] none" >> "$1"  
    echo    "[AUTHOR] none" >> "$1" 
    echo    "[SOURCE]" >> "$1"  
    echo    "[FILEPATH]Media" >> "$1"
    echo    "[DELAY]0" >> "$1"
    echo    "[COMMENT] Created using subotage - universal subtitle converter for bash" >> "$1"
    echo    "[END INFORMATION]" >> "$1" 
    echo    "[SUBTITLE]" >> "$1"
    echo    "[COLF]&HFFFFFF,[STYLE]bd,[SIZE]18,[FONT]Arial" >> "$1"
    
    
    case $time_type in
    "secs")
        tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
            awk "{ 
                    printf (\"%02d:%02d:%02d:%02d,%02d:%02d:%02d:%02d\n\",
                        (\$2/3600),((\$2/60)%60),(\$2%60),                   
                        int((\$2 - int(\$2))*100),
                        (\$3/3600),((\$3/60)%60),(\$3%60),
                        int((\$3 - int(\$3))*100));
                        for (i=4; i<=NF; i++) printf(\"%s \", \$i); 
                        printf (\"\n\n\");
             }" | tr '|' '\n' > "$1"
    ;;
    
    "hmsms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%02d:%02d:%02d:%02d,%02d:%02d:%02d:%02d\n\",
                (start[1]),(start[2]),(start[3]),
                int((start[3] - int(start[3]))*100),
                (stop[1]),(stop[2]),(stop[3]),
                int((stop[3] - int(stop[3]))*100));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  

    "hms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%02d:%02d:%02d:%02d,%02d:%02d:%02d:%02d\n\",
                (start[1]),(start[2]),(start[3]),
                (0),
                (stop[1]),(stop[2]),(stop[3]),
                (0));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;
    
    *)
    echo 1
    return
    ;;
    esac
        
    echo 0
}


# uni -> mpl2 format converter
function f_write_mpl2_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs") 
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{ printf \"[%d][%d]\", (\$2*10),(\$3*10);
            for (i=4; i<=NF; i++) printf(\"%s \", \$i); \
            printf \"\n\" }" > "$1"
    ;;
    
    "hmsms" | "hms")
    tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");                    
            printf(\"[%d][%d]\", 
             ((start[1]*3600 + start[2]*60 + start[3])*10),
             ((stop[1]*3600 + stop[2]*60 + stop[3])*10));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\" }" > "$1"     
    ;;
        
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}

# uni -> subrip format converter
function f_write_subrip_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{ 
            printf(\"%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n\",
            \$1, (\$2/3600),((\$2/60)%60),(\$2%60),
            int((\$2 - int(\$2))*1000),         
            (\$3/3600),((\$3/60)%60),(\$3%60),
            int((\$3 - int(\$3))*1000));            
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf (\"\n\n\");
         }" | tr '|' '\n' > "$1"
    ;;
    
    "hmsms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                int((start[3] - int(start[3]))*1000),
                (stop[1]),(stop[2]),(stop[3]),
                int((stop[3] - int(stop[3]))*1000));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  

    "hms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                (0),
                (stop[1]),(stop[2]),(stop[3]),
                (0));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


# uni -> fab format converter
function f_write_fab_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{ 
            printf(\"%04d : %02d:%02d:%02d:%02d  %02d:%02d:%02d:%02d\n\",
            \$1, (\$2/3600),((\$2/60)%60),(\$2%60),
            int((\$2 - int(\$2))*100),          
            (\$3/3600),((\$3/60)%60),(\$3%60),
            int((\$3 - int(\$3))*100));         
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf (\"\n\n\");
         }" | tr '|' '\n' > "$1"
    ;;
    
    "hmsms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%04d : %02d:%02d:%02d:%02d  %02d:%02d:%02d:%02d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                int((start[3] - int(start[3]))*100),
                (stop[1]),(stop[2]),(stop[3]),
                int((stop[3] - int(stop[3]))*100));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  

    "hms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%04d : %02d:%02d:%02d:%02d  %02d:%02d:%02d:%02d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                (0),
                (stop[1]),(stop[2]),(stop[3]),
                (0));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


###############################################################################
############################ format write routines ############################
###############################################################################




###############################################################################
############################### common routines ###############################
###############################################################################

# @brief provide help information
function f_print_help
{
    echo    "subotage.sh -i <input_file> -o <output_file> [optional switches]"
    echo    "version [$g_Version]" 
    echo    "   "
    echo    "All switches:"
    echo    "============="
    echo    "   -i  | --input <input_file>  - input file (mandatory)"
    echo    " "
    echo    "   -o  | --output <output_file> - output file (mandatory)"
    echo    " "
    echo    "   -if | --input-format <format> - forces input format,"
    echo    "                                   normally autodetection is done"
    echo    " "
    echo    "   -of | --output-format <format> - output format (default is srt)"
    echo    " "
    echo    "   -fi | --fps-input <fps> - framerate for reading in microdvd"
    echo    "                               (default is: $g_InputFrameRate fps)"
    echo    " "
    echo    "   -fo | --fps-output <fps> - framerate for writing in microdvd "
    echo    "                               (default is: $g_InputFrameRate fps)"
    echo    " "
    echo    "   -l  | --lasting-time <time in ms> - declare how long each subtitle"
    echo    "                               line should last in miliseconds"
    echo    "                               (default is: $g_LastingTime ms)"
    echo    " "
    echo    "   -gi | --get-info <input_file> - retrieve information about input, "
    echo    "                                   print them and exit"
    echo    " "
    echo	"   -gf | --get-formats - display supported subtitle formats only and exit"
    echo    " "
    echo	"   -gl | --get-formats-long - display supported subtitle formats "
    echo	"								(with description) and exit"
    echo    " "
    echo    "   -q  | --quiet - be quiet. Dont print any unneccesarry output"
    echo    " "
    echo    "Supported formats:"
    
    counter=0
    for fmt in ${g_FileFormats[@]}; do
        echo -e "\t$fmt - ${g_FormatDescription[$counter]}"
        counter=$(( $counter + 1 ))
    done
}


# @brief error wrapper
function f_print_error
{
    if [[ $g_Quiet -eq 1 ]]; then
        echo "Error" > /dev/stderr
    else
    
        echo "=======================================" > /dev/stderr
        echo "An error occured. Execution aborted !!!" > /dev/stderr
        echo -e "$@" > /dev/stderr
        echo "=======================================" > /dev/stderr
        echo > /dev/stderr
    fi
}

# @brief printing wrapper
function f_echo
{
    if [[ $g_Quiet -ne 1 ]]; then
        echo -e "$@"
    fi
}

# @brief try to determine the input file format
function f_guess_format
{
    lines=$(cat "$1" 2> /dev/null | wc -l)
    if [[ $lines -eq 0 ]]; then
        f_print_error "Input file has zero lines inside"
        exit
    fi
    
    detected_format="not detected"
    
    for a in "${g_FileFormats[@]}"; do
        function_name="f_is_${a}_format"
        detected_format=$($function_name "$1")
            
        if [[ $detected_format != "not detected" ]]; then
            break
        fi
    done

    echo $detected_format
}

function f_correct_overlaps
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
	num_lines=$(($(wc -l "$g_ProcTmpFile" | cut -d ' ' -f 1) - 1))
    
	# now I need to rewrite the univeral file once again
    case $time_type in
    "secs")
		# recreate the secs header
		echo "secs" > "${g_ProcTmpFile}_2"
        tail -n +2  "$g_ProcTmpFile" | tr -d '\r' |
		awk "BEGIN {
				previous_end = 0;			
				cntr = 0;
				line_cnt = 0;
				
			 }
			 {				
				 lines[cntr,0] = NF;
				 for (i=1; i<=NF; i++) lines[cntr,i] = \$i;

				 if (cntr == 0) {
					 if ((lines[1,3]+0) > (lines[0,2]+0)) lines[1,3] = lines[0,2];
				 }
				 else {
					 if ((lines[0,3]+0) > (lines[1,2]+0)) lines[0,3] = lines[1,2];
				 }
				 
				 do {
					 line_cnt++;
					 cntr = (cntr + 1) % 2;

					 if ((line_cnt >= 2 || line_cnt == $num_lines) && lines[cntr,0]>0) {
						 printf \"%s %s %s \", lines[cntr,1], lines[cntr,2], lines[cntr,3];
						 for (i=4; i<=lines[cntr,0]; i++) printf(\"%s \", lines[cntr,i]);
						 printf \"\n\"; 
					 }
				 } while (line_cnt == $num_lines)
			}" >> "${g_ProcTmpFile}_2"

		# overwrite the original file
		mv "${g_ProcTmpFile}_2" "${g_ProcTmpFile}"
	;;
    
    "hms" | "hmsms")
# it's very unlikely that a file in this format will have any overlapping time stamps
# for the moment this is to be implemented
	return
    ;;
    
    *)
    return
    ;;
    esac	
}

###############################################################################
############################### common routines ###############################
###############################################################################



###############################################################################
############################## parameter parsing ##############################
###############################################################################

# if no arguments are given, then print help and exit
if [[ $# -eq 0 ]] || [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
    f_print_help
    exit
fi

# command line arguments parsing
while [ $# -gt 0 ]; do
    
    case "$1" in
    
        # input file
        "-i" | "--input")
        shift       
        if [[ -z "$1" ]] || ! [[ -e "$1" ]]; then
            f_print_error "No input file specified or file doesnt exist !!! [$1]"
            exit                        
        fi
        g_InputFile="$1"
        ;;
        
        # output file
        "-o" | "--output")
        shift       
        if [[ -z "$1" ]]; then
            f_print_error "No output file specified !!!"
            exit                
        fi
        g_OutputFile="$1"       
        ;;
        
        # input format
        "-if" | "--input-format")
        shift       
        if [ -z "$1" ]; then
            f_print_error "No input format specified"
            exit
        fi

        if_valid=0
        for i in "${g_FileFormats[@]}"; do      
            if [[ "$i" == "$1" ]]; then
                if_valid=1
                break
            fi      
        done
        
        if [[ if_valid -eq 0 ]]; then
            f_print_error "Specified input format is not valid: [$1]"
            exit
        fi      
        g_InputFormat=$1        
        ;;
        
        # output format
        "-of" | "--output-format")
        shift       
        if [ -z "$1" ]; then
            f_print_error "No output format specified"
            exit
        fi
        
        of_valid=0
        for i in "${g_FileFormats[@]}"; do      
            if [[ "$i" == "$1" ]]; then
                of_valid=1
                break
            fi      
        done
        
        if [[ of_valid -eq 0 ]]; then
            f_print_error "Specified output format is not valid: [$1]"
            exit
        fi      
        g_OutputFormat=$1
        ;;
        
        # lasting time
        "-l" | "--lasting-time")
        shift       
        if [ -z "$1" ]; then
            f_print_error "No time specified specified"
            exit
        fi
        
        dot_removed=$(echo "$1" | tr -d '.,')
        g_LastingTime="$1"              
        ;;
        
        # fps for input file
        "-fi" | "--fps-input")
        shift       
        if [[ -z "$1" ]]; then
            f_print_error "No framerate specified"
            exit
        fi
        g_InFpsGiven=1
        
        # check if fps is integer or float
        if [[ -n $(echo "$1" | tr -d '[\n\.0-9]') ]]; then
            f_print_error "Framerate is not in an acceptable number format [$1]"
            exit            
        else
            g_InputFrameRate="$1"
        fi      
        ;;
        
        # get input info
        "-gi" | "--get-info")
        shift       
        if [[ -z "$1" ]] || ! [[ -e "$1" ]]; then
            f_print_error "No input file specified or file doesnt exist !!!"
            exit                        
        fi
        
        detectedFormat=$(f_guess_format "$1")
        echo $detectedFormat
        exit
        ;;

        # get formats
        "-gf" | "--get-formats")        
        echo ${g_FileFormats[@]}
        exit
        ;;

        # get formats
        "-gl" | "--get-formats-long")        
        counter=0
		for fmt in ${g_FileFormats[@]}; do
			echo -e "\t$fmt - ${g_FormatDescription[$counter]}"
			counter=$(( $counter + 1 ))
		done
        exit
        ;;

            
        # fps for output file
        "-fo" | "--fps-output")
        shift       
        if [ -z "$1" ]; then
            f_print_error "No framerate specified"
            exit
        fi
        
        # check if fps is integer or float      
        if [[ -n $(echo "$1" | tr -d '[\n\.0-9]') ]]; then
            f_print_error "Framerate is not in an acceptable number format [$1]"
            exit
        else
            g_OutputFrameRate="$1"
        fi      
        ;;
        
        # be quiet flag
        "-q" | "--quiet")
        g_Quiet=1
        ;;

        # sanity check for unknown parameters
        *)
        f_print_error "Unknown parameter: [$1]"
        exit
        ;;
    esac
    
    
    shift
done

# filenames validation
if [[ $g_InputFile == "none" ]] || [[ $g_OutputFile == "none" ]]; then
    f_print_error "Input/Output file not specified !!!"
    exit
fi

# handle the input file format
if [[ $g_InputFormat == "none" ]]; then
    g_DetectedFormat=$(f_guess_format "$g_InputFile")
    
    if [[ $g_DetectedFormat = "not detected" ]]; then
        f_print_error "Invalid Input File Format!\nSpecify input format manually to override autodetection."
        exit
    fi
    
    g_InputFormat=$g_DetectedFormat
    g_InputFormatData=( $(echo $g_InputFormat) )
    g_FormatDetected=1
else
    g_InputFormatData=( "$g_InputFormat" 1 0 )
fi

# some info
f_echo "Input File Format Detected: [${g_InputFormatData[@]}]"
f_echo "Actual Data found at line: [${g_InputFormatData[1]}]"
f_echo "Output Format Selected: [$g_OutputFormat]"


# format specific data manipulation operations
# executed only if format detection was performed
if [[ $g_FormatDetected -eq 1 ]]; then  
    case "${g_InputFormatData[0]}" in
        
        "microdvd")
        if [[ $g_InFpsGiven -eq 0 ]]; then

            tmpFps=${g_InputFormatData[$(( ${#g_InputFormatData[@]} - 1 ))]}                        
            if [[ $tmpFps != "0" ]]; then
                g_InputFrameRate=$tmpFps
            fi
        fi
        
        f_echo "Input FPS: [$g_InputFrameRate]"       
        ;;
        
        *)
        ;;
    esac
fi

# the same for output format
case "$g_OutputFormat" in   
    "microdvd") 
    f_echo "Output FPS: [$g_OutputFrameRate]"     
    ;;
    
    *)
    ;;
esac


# check if conversion is really needed
if [[ ${g_InputFormatData[0]} == $g_OutputFormat ]]; then
    
    # additional format specific checks
    case "${g_InputFormatData[0]}" in
    
        "microdvd")
            if [[ $g_InputFrameRate -eq $g_OutputFrameRate ]]; then
                f_print_error "Convertion aborted. In Fps == Out Fps == [$g_InputFrameRate]"
                exit
            fi
        ;;
    
        *)
        f_print_error "No convertion is needed input format == output format"
        exit
        ;;
    esac
fi

###############################################################################
############################## parameter parsing ##############################
###############################################################################



###############################################################################
############################## actual convertion ##############################
###############################################################################

g_Reader="f_read_${g_InputFormatData[0]}_format"
g_Writer="f_write_${g_OutputFormat}_format"

echo > "$g_ProcTmpFile"


# input file, first valid line, format specific data
status=$($g_Reader "$g_InputFile" "${g_InputFormatData[1]}" "${g_InputFormatData[2]}")

if [[ $status -ne 0 ]]; then
    f_print_error "Reading error. Error code: [$status]"
    exit
else
	f_correct_overlaps;
    status=$($g_Writer "$g_OutputFile")
    
    if [[ $status -ne 0 ]]; then
        f_print_error "Writing error. Error code: [$status]"
        exit
    fi
fi
    
# remove the temporary processing file
rm -rf "$g_ProcTmpFile"
echo "Done"

###############################################################################
############################## actual convertion ##############################
###############################################################################
# EOF
