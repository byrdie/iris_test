pro read_iris, files, index, data, xll, yll, nx, ny, _extra=_extra,nodata=nodata, history=history

;+
;   Name: read_iris
;
;   Purpose: like the Name says...
;
;   Input Parameters:
;      files - list of one or more IRIS data files, compressed or uncompressed, level=?
;
;   Output Parameters:
;      index - meta data / structure vector associated with IRISFDILES
;      data - optional DATA
;
;   Keyword Parameters:
;      xll,yll,nx,ny - optional subfield to read (see read_sdo/mreadfits_tilecomp)
;      _extra - keyword inherit -> read_sdo -> mreadfits_tilecomp etc. 
;             { outdir, /uncomp_delete,/use_shared,only_tags,/noshell .... etc)
;     history (switch)  - if set, include .HISTORY (possible future default after testing/optimiztion)
;
;   Method:
;      for now setup/call 'read_sdo.pro' 
;
;   Restrictions:
;      I'll know more in a few minutes - let me get back to you on that
;   
;   History:
;      22-apr-2013 - S.L.Freeland 
;      15-jul-2013 - S.L.Freeland - get jsoc typing template from $SSW_IRIS/data/ dbase
;      17-jul-2013 - S.L.Freeland - (first light!) - force above - need to review why
;                    later, that same day... add DATE_OBS if missing (from t_obs-.5exptime)
;      18-jul-2013 - restore tags clobbered by last nights change ;
;       9-oct-2013 - S.L.Freeland add /HISTORY 
;      15-oct-2013 - S.L.Freeland - assure naxis/naxis1/naxis2 valid for tile comp input
;       7-may-2015 - S.L.Freeland - append iris_prep tags to template for L1.5 (iris_prep_keyword_template.pro)
;                                   
;-
;
nodata=n_params() lt 3 or keyword_set(nodata)
next=get_fits_nextend(files(0))
;
if n_elements(files) gt 0 and 1-required_tags(_extra,/template) then begin ; force jsoc-like typing
   read_sdo,files[0],indxx,only='fsn,flat_rec,IPRPVER'
   template=iris_jsoc_strtemplate(required_tags(indxx,/flat_rec)*1) ; auto select template
   if required_tags(indxx,'IPRPVER') then template=iris_prep_keyword_template(template) ; L1.5 tag append

   if required_tags(_extra,/ONLY_TAGS) then template=str_subset(template,gt_tagval(_extra,/ONLY_TAGS,missing=tag_names(template)))
   _extra=add_tag(_extra,template,'template')
endif

case 1 of 
   n_params() < 2: box_message,'IDL> read_sdo,files,index [,data [,xll,yll,nx,ny]]
   n_params() eq 2 or nodata:  mreadfits_header,files,index,exten=next,_extra=_extra
   n_params() eq 3: read_sdo,files,index,data,_extra=_extra, /noshell
   else: read_sdo,files,index,data,xll,yll,nx,ny,_extra=_extra, /noshell
endcase

if n_params() le 3 then begin
   temp=index
   mreadfits_header,files,index,template=template,ext=(is_tile_compressed(files[0]))(0)  ; todo see why I need to do this
   if 1-required_tags(index,'naxis1') and required_tags(temp,'naxis1') then begin 
      index=add_tag(index,2,'naxis',index=0)
      index=add_tag(index,temp.naxis1,'naxis1',index='naxis')
      index=add_tag(index,temp.naxis2,'naxis2',index='naxis1')
   endif
   if is_tile_compressed(files[0]) and 1-required_tags(index,/naxis1) then begin
      ctags='znaxis,znaxis1,znaxis2'
      catags=str2arr(ctags)
      mreadfits_header,files,iix,ext=1,only=ctags
      for z=0,n_tags(iix)-1 do begin 
         index=add_tag(index,gt_tagval(iix,catags[z]),str_replace(catags[z],'z',''),index=z)
      endfor
   endif 
endif
if 1-required_tags(index,/date_obs) and required_tags(index,'t_obs,exptime') then begin 
   dobs=anytim(anytim(index.t_obs) - (.5*index.exptime),/ccsds)
   index=add_tag(index,dobs,'date_obs')
endif

if keyword_set(history) then begin 
   mreadfits_header,files,iihistory,only='history', ext=(is_tile_compressed(files[0]))(0)
   index=rep_tag_value(index,iihistory.history,'history')
endif


return
end


