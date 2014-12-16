
/* 
 * A simple function to append the value of the ocid in the form to the url
 * if it is set. If the Orcid ID is not specified then fall back to the email
 * address and if this is not set in the profile then try and find it from the 
 * current form fields. 
*/


function EPJS_appendOrcidIfSet( prefix, field, url, email ) {
   var current_orcid = document.getElementById( prefix+"_"+field ).value;
   if (null != current_orcid && current_orcid.length > 16 ) {
      url += "&orcid="+current_orcid;
   } else if ( null != email && email.length > 4  ) {
      url += "&email="+email;
   } else {
      // user may have just typed the email address so try and find the field
      var fields = document.getElementsByClassName("ep_form_text");
      for ( var i=0; i<fields.length; i++) {
         var found =  fields[i].name.search( "email" ); 
         if ( found > 2 ) {
            email = fields[i].value;
         }
      }
      if ( null != email && email.length > 4  ) {
         url += "&email="+email;
      }
   }

   window.location.assign( url );
};

