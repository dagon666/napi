#!/bin/bash

g_InFpsGiven=0
g_FormatDetected=0
g_ProcTmpFile="/tmp/subotage_$$.tmp"

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
    if [ "${#g_InputFormatData[*]}" -gt 3 ]; then
        
        hour_digits="${g_InputFormatData[2]}"
        multiline="${g_InputFormatData[3]}"
        delimiter="$(echo ${g_InputFormatData[4]} | tr -d '[]')"
    fi
    
    echo "hms" > $g_ProcTmpFile
    
    if [ "$multiline" = "no" ]; then
    
        if [ "$delimiter" = ":" ]; then
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { 
						FS=\"$delimiter\";
						line_processed = 1;
					}; 
					/^ *$/ {
						next;
					};
					NF { 
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
        if [ "$delimiter" = ":" ]; then
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
    echo "secs" > "$g_ProcTmpFile"
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
    echo "secs" > "$g_ProcTmpFile"
    tail -n +"$2" "$1" | tr -d '\r' | 
        awk "BEGIN { 
				FS=\"[][]+\";
				line_processed = 1;
			}; 
			/^ *$/ {
				next;
			}
			NF { 
				printf \"%s %s %s \", line_processed++, (\$2/10), (\$3/10);
				for (i=4; i<=NF; i++) printf(\"%s\", \$i);
				printf \"\n\"; 
			}" >> "$g_ProcTmpFile"
    echo 0
}

# subrip -> uni format converter
function f_read_subrip_format
{
    echo "hmsms" > "$g_ProcTmpFile"
    
    if [ "$3" = "inline" ]; then
    
        tail -n +"$2" "$1" | tr -d '\r' | 
            awk "BEGIN { 
					FS=\"\n\"; 
					RS=\"\"; 
				};
                NF {  
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
             }" | tr '|' '\n' >> "$1"
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
            printf \"\n\n\" }" | tr '|' '\n' >> "$1"
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
            printf \"\n\n\" }" | tr '|' '\n' >> "$1"
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

###############################################################################
############################ format write routines ############################
###############################################################################

###############################################################################
############################### common routines ###############################
###############################################################################

function f_correct_overlaps
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
	num_lines=$(( $(cat "$g_ProcTmpFile" | count_lines) - 1))
    
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

echo > "$g_ProcTmpFile"

# input file, first valid line, format specific data
status=$($g_Reader "$g_InputFile" "${g_InputFormatData[1]}" "${g_InputFormatData[2]}")

if [ "$status" -ne 0 ]; then
    f_print_error "Reading error. Error code: [$status]"
    exit -1
else
	f_correct_overlaps
    status=$($g_Writer "$g_OutputFile")
    
    if [ "$status" -ne 0 ]; then
        f_print_error "Writing error. Error code: [$status]"
        exit -1
    fi
fi
    
# remove the temporary processing file
rm -rf "$g_ProcTmpFile"

# EOF
