# Package Tap3edit (http://www.tap3edit.com)
# designed to decode, modify and encode Roaming GSM TAP/RAP 
# files
# 
# Copyright (c) 2004 Javier Gutierrez. All rights reserved.
# Email Address <javier.gutierrez@tap3edit.com>. 
# This program is free software; you can redistribute 
# it and/or modify it under the same terms as Perl itself.
# 
# This program contains TAP and RAP ASN.1 Specification. The
# ownership of the TAP/RAP ASN.1 Specifications belong to
# the GSM MoU Association (http://www.gsm.org) and should be
# used under following conditions:
# 
# Copyright (c) 2000 GSM MoU Association. Restricted − Con­
# fidential Information.  Access to and distribution of this
# document is restricted to the persons listed under the
# heading Security Classification Category*. This document
# is confidential to the Association and is subject to copy­
# right protection.  This document is to be used only for
# the purposes for which it has been supplied and informa­
# tion contained in it must not be disclosed or in any other
# way made available, in whole or in part, to persons other
# than those listed under Security Classification Category*
# without the prior written approval of the Association. The
# GSM MoU Association (âAssociationâ) makes no representa­
# tion, warranty or undertaking (express or implied) with
# respect to and does not accept any responsibility for, and
# hereby disclaims liability for the accuracy or complete­
# ness or timeliness of the information contained in this
# document. The information contained in this document may
# be subject to change without prior notice.



package TAP3::Tap3edit;

use strict;
use Convert::ASN1 qw(:io :debug); # Handler of ASN1 Codes. Should be installed first.
use File::Spec;
use File::Basename;
use Carp;


BEGIN {
	use Exporter;
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = "0.25";
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto ;
	my $self  = {};
	$self->{_filename} = undef;
	$self->{_spec_file} = undef;
	$self->{_supl_spec_file} = undef;
	$self->{_asn} = Convert::ASN1->new();
	$self->{_dic_decode} = {};                      # Stores the file decode with $self->{_dic_asn}
	$self->{_dic_asn} = $self->{_asn};              # Stores the ASN Specification
	$self->{spec_path} = [ ( grep(-d $_, map(File::Spec->catdir($_, qw(TAP3 Spec)), @INC)), File::Spec->curdir) ];
	$self->{_version} = undef;
	$self->{_release} = undef;
	$self->{_supl_version} = undef; 		# Tap version inside the RAP file
	$self->{_supl_release} = undef; 		# Tap release inside the RAP file
	$self->{_file_type} = undef;			# TAP or RAP
	$self->{error} = undef;
	bless ($self, $class);
	return $self;
}


#----------------------------------------------------------------
# Method:       structure
# Description:  Contains the structure of the TAP/RAP file into 
#               a HASH 
# Parameters:   N/A 
# Returns:      HASH
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub structure {
	my $self = shift;
	if (@_) { $self->{_dic_decode} = shift }
	return $self->{_dic_decode};
}


#----------------------------------------------------------------
# Method:       version
# Description:  contains and updates the main version of the 
#               TAP/RAP file
# Parameters:   N/A
# Returns:      SCALAR: version number
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub version {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_version} ) { 
			$self->{_version} = shift ;
		} else {
			$self->{error}="The Version cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_version};
}


#----------------------------------------------------------------
# Method:       supl_version
# Description:  contains and updates the suplementary version of the 
#               RAP file
# Parameters:   N/A
# Returns:      SCALAR: release number
# Type:         Public
# Restrictions: Valid just for RAP files
#----------------------------------------------------------------
sub supl_version {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_supl_version} ) { 
			$self->{_supl_version} = shift ;
		} else {
			$self->{error}="The Suplementary Version cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_supl_version};
}

#----------------------------------------------------------------
# Method:       release
# Description:  contains and updates the main release of the 
#               TAP/RAP file
# Parameters:   N/A
# Returns:      SCALAR: release number
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub release {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_release} ) { 
			$self->{_release} = shift ;
		} else {
			$self->{error}="The Release cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_release};
}


#----------------------------------------------------------------
# Method:       supl_release
# Description:  contains and updates the suplementary release of the 
#               RAP file
# Parameters:   N/A
# Returns:      SCALAR: release number
# Type:         Public
# Restrictions: Valid just for RAP files
#----------------------------------------------------------------
sub supl_release {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_supl_release} ) { 
			$self->{_supl_release} = shift ;
		} else {
			$self->{error}="The Suplementary Release cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_supl_release};
}

#----------------------------------------------------------------
# Method:       file_type
# Description:  contains and updates the type of the file
#               the values can be: TAP/RAP.
# Parameters:   N/A
# Returns:      SCALAR: file type ("RAP","TAP")
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub file_type {
	my $self = shift;
	if ( @_ ) {
		if ( ! $self->{_file_type} ) { 
			my $file_type = shift;

			unless ($file_type =~ /^[TR]AP$/) {
				croak("Unsupported File Type $file_type");
			}

			$self->{_file_type} = $file_type ;
		} else {
			$self->{error}="The File Type cannot be changed";
			croak $self->error();
		}
	}
	return $self->{_file_type};
}


#----------------------------------------------------------------
# Method:       get_info
# Description:  gets the basic information of the TAP/RAP files:
#               version, release, supl_version (for RAP files),
#               supl_release (for RAP files), file type.
# Parameters:   filename
# Returns:      N/A
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub get_info {
	my $self = shift;
	my $filename = shift;
	$self->_filename($filename);
	$self->_get_file_version || return undef ;
}


#----------------------------------------------------------------
# Method:       _filename
# Description:  contains and updates the name of the TAP/RAP
#               files
# Parameters:   filename
# Returns:      filename
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _filename {
	my $self = shift;
	if (@_) { $self->{_filename} = shift }
	return $self->{_filename};
}


#----------------------------------------------------------------
# Method:       spec_file
# Description:  contains and updates the name of the file
#               with specifications ASN.1
# Parameters:   filename of specifications ASN.1
# Returns:      filename of specifications ASN.1
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub spec_file {
	my $self = shift;
	if (@_) { $self->{_spec_file} = shift }
	return $self->{_spec_file};
}


#----------------------------------------------------------------
# Method:       supl_spec_file
# Description:  contains and updates the name of the file
#               with specifications ASN.1 for the version of 
#               the TAP file included in the RAP file.
# Parameters:   filename of specifications ASN.1
# Returns:      filename of specifications ASN.1
# Type:         Public
# Restrictions: Valid just for RAP files
#----------------------------------------------------------------
sub supl_spec_file {
	my $self = shift;
	if (@_) { $self->{_supl_spec_file} = shift }
	return $self->{_supl_spec_file};
}


#----------------------------------------------------------------
# Method:       _dic_decode
# Description:  contains and updates the HASH which stores
#               the decoded information from the TAP/RAP file.
#               This variable is also used for the method:
#               "structure".
# Parameters:   HASH
# Returns:      HASH
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _dic_decode {
	my $self = shift;
	if (@_) { $self->{_dic_decode} = shift }
	return $self->{_dic_decode};
}


#----------------------------------------------------------------
# Method:       _dic_asn
# Description:  contains and updates the object used to store
#               the tree of the specifictions ASN.1 starting 
#               from the DataInterChange/RapDataInterChange tag.
# Parameters:   object
# Returns:      object
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _dic_asn {
	my $self = shift;
	if (@_) { $self->{_dic_asn} = shift }
	return $self->{_dic_asn};
}


#----------------------------------------------------------------
# Method:       _asn
# Description:  contains and updates the object used to store
#               the constructor of Convert::ASN1
# Parameters:   object
# Returns:      object
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _asn {
	my $self = shift;
	if (@_) { $self->{_asn} = shift }
	return $self->{_asn};
}


#----------------------------------------------------------------
# Method:       _asn_path
# Description:  contains the list of PATH where 
#               to find the specifications ASN.1.
#               The default values are "TAP3/Spec" from the insta-
#               llation and "." (current directory). The used
#               array (spec_path) can be updated with new PATHs
# Parameters:   ARRAY
# Returns:      ARRAY
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _asn_path {
	my $self = shift;
	return $self->{spec_path};
}


#----------------------------------------------------------------
# Method:       _prepare_bci
# Description:  contains the BatchControlInfo to decode the 
#               "header" of TAP files and found out their
#               version and release.
# Parameters:   N/A
# Returns:      object
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _prepare_bci()
{
	my $self = shift;

	# parse ASN.1 desciptions
	# First we load the BatchControlInfo to know the version and release 
	# of the files.

	my $asn_bci = Convert::ASN1->new;
	$asn_bci->prepare(<<ASN1) or do { $self->{error}=$asn_bci->error; return undef };
	--
	-- The following ASN.1 Specification defines only the BatchControlInfo.
	-- Usefull to find out which version and release has the file.
	--

	BatchControlInfo ::= [APPLICATION 4] SEQUENCE
	{
	 sender Sender OPTIONAL,
	 recipient Recipient OPTIONAL,
	 fileSequenceNumber FileSequenceNumber OPTIONAL,
	 fileCreationTimeStamp FileCreationTimeStamp OPTIONAL,
	 transferCutOffTimeStamp TransferCutOffTimeStamp OPTIONAL,
	 fileAvailableTimeStamp FileAvailableTimeStamp OPTIONAL,
	 specificationVersionNumber SpecificationVersionNumber OPTIONAL,
	 releaseVersionNumber ReleaseVersionNumber OPTIONAL,
	 fileTypeIndicator FileTypeIndicator OPTIONAL,
	 rapFileSequenceNumber RapFileSequenceNumber OPTIONAL,
	 operatorSpecInformation OperatorSpecInformation OPTIONAL
	}

	Sender ::= [APPLICATION 196] PlmnId

	Recipient ::= [APPLICATION 182] PlmnId

	PlmnId ::= [APPLICATION 169] AsciiString --(SIZE(5))

	FileCreationTimeStamp ::= [APPLICATION 108] DateTimeLong

	TransferCutOffTimeStamp ::= [APPLICATION 227] DateTimeLong

	FileAvailableTimeStamp ::= [APPLICATION 107] DateTimeLong

	SpecificationVersionNumber ::= [APPLICATION 201] INTEGER

	ReleaseVersionNumber ::= [APPLICATION 189] INTEGER

	FileTypeIndicator ::= [APPLICATION 110] AsciiString --(SIZE(1))

	RapFileSequenceNumber ::= [APPLICATION 181] FileSequenceNumber

	OperatorSpecInformation ::= [APPLICATION 163] AsciiString

	DateTimeLong ::= [APPLICATION 84] SEQUENCE 
	{
	 localTimeStamp LocalTimeStamp OPTIONAL ,
	 utcTimeOffset UtcTimeOffset OPTIONAL
	}

	LocalTimeStamp ::= [APPLICATION 16] NumberString --(SIZE(14))

	UtcTimeOffset ::= [APPLICATION 231] AsciiString --(SIZE(5))

	AsciiString ::= OCTET STRING

	FileSequenceNumber ::= [APPLICATION 109] NumberString --(SIZE(5))

	NumberString ::= OCTET STRING

	-- END

ASN1

	return $asn_bci;
}


#----------------------------------------------------------------
# Method:       _prepare_rbci
# Description:  contains the RapBatchControlInfo to decode the 
#               "header" of RAP files and found out their
#               version and release, and version and release of its 
#               TAP file (stored into supl_version and 
#               supl_release)
# Parameters:   N/A
# Returns:      object
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _prepare_rbci()
{
	my $self = shift;

	# parse ASN.1 desciptions
	# First we load the RapBatchControlInfo to know the version and release 
	# of the RAP files.

	my $asn_bci = Convert::ASN1->new;
	$asn_bci->prepare(<<ASN1) or do { $self->{error}=$asn_bci->error; return undef };
	--
	-- The following ASN.1 Specification defines only the RapBatchControlInfo.
	-- Usefull to find out which version and release has the RAP file.
	--

	RapBatchControlInfo ::= [APPLICATION 537] SEQUENCE
	{
	sender                          Sender,
	recipient                               Recipient,
	rapFileSequenceNumber           RapFileSequenceNumber,
	rapFileCreationTimeStamp        RapFileCreationTimeStamp,
	rapFileAvailableTimeStamp       RapFileAvailableTimeStamp,
	specificationVersionNumber      SpecificationVersionNumber      OPTIONAL,
	releaseVersionNumber            ReleaseVersionNumber            OPTIONAL,
	rapSpecificationVersionNumber   RapSpecificationVersionNumber,
	rapReleaseVersionNumber         RapReleaseVersionNumber,
	fileTypeIndicator                       FileTypeIndicator                       OPTIONAL,
	roamingPartner                  RoamingPartner                  OPTIONAL,
	operatorSpecList                        OperatorSpecList                        OPTIONAL
	}

	Sender ::= [APPLICATION 196] PlmnId

	Recipient ::= [APPLICATION 182] PlmnId

	PlmnId ::= [APPLICATION 169] AsciiString --(SIZE(5))

	RapFileSequenceNumber ::= [APPLICATION 181] FileSequenceNumber

	RapFileCreationTimeStamp ::= [APPLICATION 526] DateTimeLong

	RapFileAvailableTimeStamp ::= [APPLICATION 525] DateTimeLong

	SpecificationVersionNumber ::= [APPLICATION 201] INTEGER

	ReleaseVersionNumber ::= [APPLICATION 189] INTEGER

	RapSpecificationVersionNumber ::= [APPLICATION 544] INTEGER

	RapReleaseVersionNumber ::= [APPLICATION 543] INTEGER

	FileTypeIndicator ::= [APPLICATION 110] AsciiString --(SIZE(1))

	RoamingPartner ::= [APPLICATION 550] PlmnId

	OperatorSpecList ::= [APPLICATION 551] SEQUENCE OF OperatorSpecInformation

	OperatorSpecInformation ::= [APPLICATION 163] AsciiString

	DateTimeLong ::= [APPLICATION 84] SEQUENCE 
	{
	 localTimeStamp LocalTimeStamp OPTIONAL ,
	 utcTimeOffset UtcTimeOffset OPTIONAL
	}

	LocalTimeStamp ::= [APPLICATION 16] NumberString --(SIZE(14))

	UtcTimeOffset ::= [APPLICATION 231] AsciiString --(SIZE(5))

	AsciiString ::= OCTET STRING

	FileSequenceNumber ::= [APPLICATION 109] NumberString --(SIZE(5))

	NumberString ::= OCTET STRING

	-- END

ASN1

	return $asn_bci;
}


#----------------------------------------------------------------
# Method:       _prepare_not
# Description:  contains the Notification struct. to decode the 
#               "header" of empty TAP files and found out their
#               version and release.
# Parameters:   N/A
# Returns:      object
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _prepare_not()
{
	my $self = shift;

	# parse ASN.1 desciptions
	# First we load the Notification to know the version and release 
	# of the files.

	my $asn_not = Convert::ASN1->new;
	$asn_not->prepare(<<ASN1) or do { $self->{error}=$asn_not->error; return undef };
	--
	-- The following ASN.1 Specification defines only the Notification.
	-- Usefull to find out which version and release has the file.
	--

	Notification ::= [APPLICATION 2] SEQUENCE
	{
	 sender Sender OPTIONAL,
	 recipient Recipient OPTIONAL,
	 fileSequenceNumber FileSequenceNumber OPTIONAL,
	 rapFileSequenceNumber RapFileSequenceNumber OPTIONAL,
	 fileCreationTimeStamp FileCreationTimeStamp OPTIONAL,
	 fileAvailableTimeStamp FileAvailableTimeStamp OPTIONAL,
	 transferCutOffTimeStamp TransferCutOffTimeStamp OPTIONAL,
	 specificationVersionNumber SpecificationVersionNumber OPTIONAL,
	 releaseVersionNumber ReleaseVersionNumber OPTIONAL,
	 fileTypeIndicator FileTypeIndicator OPTIONAL,
	 operatorSpecInformation OperatorSpecInfoList OPTIONAL
	}


	Sender ::= [APPLICATION 196] PlmnId

	Recipient ::= [APPLICATION 182] PlmnId

	PlmnId ::= [APPLICATION 169] AsciiString --(SIZE(5))

	FileCreationTimeStamp ::= [APPLICATION 108] DateTimeLong

	TransferCutOffTimeStamp ::= [APPLICATION 227] DateTimeLong

	FileAvailableTimeStamp ::= [APPLICATION 107] DateTimeLong

	SpecificationVersionNumber ::= [APPLICATION 201] INTEGER

	ReleaseVersionNumber ::= [APPLICATION 189] INTEGER

	FileTypeIndicator ::= [APPLICATION 110] AsciiString --(SIZE(1))

	RapFileSequenceNumber ::= [APPLICATION 181] FileSequenceNumber

	OperatorSpecInfoList ::= [APPLICATION 162] SEQUENCE OF OperatorSpecInformation

	OperatorSpecInformation ::= [APPLICATION 163] AsciiString

	DateTimeLong ::= [APPLICATION 84] SEQUENCE 
	{
	 localTimeStamp LocalTimeStamp OPTIONAL ,
	 utcTimeOffset UtcTimeOffset OPTIONAL
	}

	LocalTimeStamp ::= [APPLICATION 16] NumberString --(SIZE(14))

	UtcTimeOffset ::= [APPLICATION 231] AsciiString --(SIZE(5))

	AsciiString ::= OCTET STRING

	FileSequenceNumber ::= [APPLICATION 109] NumberString --(SIZE(5))

	NumberString ::= OCTET STRING

	-- END

ASN1

	return $asn_not;
}

#----------------------------------------------------------------
# Function:     bcd_to_hexa
# Description:  Converts the input binary format from the TAP/RAP
#               files into Hexadecimal.
# Parameters:   binary_string
# Returns:      hexadecimal value
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub bcd_to_hexa
{
	my $i;
	my $in=shift;
	my $out="";
	my $out_tmp;
	for ($i=0;$i<length($in);$i++) {
		my $ascii=ord(substr($in,$i,1));
		$out_tmp=sprintf ("%02x",$ascii);
		$out=$out.$out_tmp;
	}
	return $out;
}


#----------------------------------------------------------------
# Function:     bcd_to_asc
# Description:  Converts the input binary format from the TAP/RAP
#               files into ascii.
# Parameters:   binary_string
# Returns:      ascii value
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub bcd_to_asc
{
	my $i;
	my $in=shift;
	my $out="";
	my $out_tmp;
	for ($i=0;$i<length($in);$i++) {
		my $ascii=ord(substr($in,$i,1));
		$out_tmp=sprintf ("%03d",$ascii);
		$out=$out.$out_tmp;
	}
	return $out;
}



#----------------------------------------------------------------
# Method:       _get_bci
# Description:  returns the binary BatchControlInfo/
#               RapBatchControlInfo from the TAP/RAP file.
# Parameters:   N/A
# Returns:      SCALAR
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _get_bci
{
	my $self=shift;
	my $type=shift; # TAP, RAP or NOT

	# This function returns the BatchControlInfo string of hexadecimal

	# Because all versions have the same BatchControlInfo we can load just this
	# part to find out the version and release. (In fact all information from
	# this section is available).

	my $filename=$self->_filename;
	my $bci;		# Complete BCI.
	my $bci_tag;		# TAG number of the BCI.
	my $bci_size;		# Size of the complete BCI.
	my $bci_body;		# The rest of the BCI.

	open FILE, "<$filename" or do { $self->{error}="$! for file $filename" ; return undef };
	binmode FILE;
	

	if ( $type eq "TAP" ) {

		read FILE, $bci_tag, 2;
		read FILE, $bci_tag, substr(bcd_to_hexa($bci_tag),3,1);
		read FILE, $bci_tag, 1;
		read FILE, $bci_size, 1;
		read FILE, $bci_body, bcd_to_asc($bci_size); # To read the body we convert the hexa size into ascii

	} elsif ( $type eq "NOT" ) {

		read FILE, $bci_tag, 1;
		read FILE, $bci_size, 1;
		read FILE, $bci_body, bcd_to_asc($bci_size); # To read the body we convert the hexa size into ascii

	} elsif ( $type eq "RAP" ) {

		read FILE, $bci_tag, 4;
		read FILE, $bci_tag, substr(bcd_to_hexa($bci_tag),3,1);
		read FILE, $bci_tag, 3;
		read FILE, $bci_size, 1;
		read FILE, $bci_body, bcd_to_asc($bci_size); # To read the body we convert the hexa size into ascii

	}

	close FILE;
	$bci=$bci_tag.$bci_size.$bci_body;
	return $bci;

}


#----------------------------------------------------------------
# Method:       _get_file_version
# Description:  sets the file version/release of the TAP/RAP file
#               reading the BatchControlInfo
# Parameters:   N/A
# Returns:      N/A
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _get_file_version
{
	## This function returns the version and release of the input file
	## TAP or RAP.

	my $self=shift;

	my $filename=$self->_filename;


	## 
	## 1. If we decode the file we just encoded the file type, version and release should be empty
	## 

	$self->{_version} = undef;
	$self->{_release} = undef;
	$self->{_supl_version} = undef; 		# Tap version inside the RAP file
	$self->{_supl_release} = undef; 		# Tap release inside the RAP file
	$self->{_file_type}=undef;


	##
	## 2. We get the file_type, guessing and trying all the possible cases (tap, rap, notific)
	## 

	my $asn;
	my $find_string;
	my $bci_asn;
	my $bci_buf;
	my $bci_dec;

	
	## 
	## 2.1 We try first with a normal TAP structure.

	my $guess_file_type="TAP";


	## 2.1.1 We prepare the structure to use, In this case the BatchControlInfo one.

	$asn=_prepare_bci() || return undef; # Here the declaration of the ASN.1 for the BCI is prepared
	$find_string="BatchControlInfo";


	## 2.1.2 We need just this part of the structure for the version and release.

	$bci_asn = $asn->find($find_string) or do { $self->{error}=$asn->error; return undef };


	## 2.1.3 The fisical "header" of the file is dump into $bci_buf

	$bci_buf = $self->_get_bci($guess_file_type) || return undef;


	## 2.1.4 Decode file buffer into the ASN1 tree.

	$bci_dec = $bci_asn->decode($bci_buf);


	## 2.1.5 If error let's do next try.

	if ( $bci_asn->error ) {

		
		## 
		## 2.2 Because the structure of the notification files is different we also try it.

		my $guess_file_type="NOT";


		## 2.2.1 We prepare the structure to use, In this case the Notification one.

		$asn=_prepare_not() || return undef; # Here the declaration of the ASN.1 for the BCI is prepared
		$find_string="Notification";


		## 2.2.2 We need just this part of the structure for the version and release.

		$bci_asn = $asn->find($find_string) or do { $self->{error}=$asn->error; return undef };


		## 2.2.3 The fisical "header" of the file is dump into $bci_buf

		$bci_buf = $self->_get_bci($guess_file_type) || return undef;


		## 2.2.4 Decode file buffer into the ASN1 tree.

		$bci_dec = $bci_asn->decode($bci_buf);


		## 2.2.5 If error let's do next try.

		if ( $bci_asn->error ) {


			## 
			## 2.3 At the end we try with the RAP structure.

			my $guess_file_type="RAP";


			## 2.3.1 We prepare the structure to use, In this case the RapBatchControlInfo one.

			$asn=_prepare_rbci() || return undef; # Here the declaration of the ASN.1 for the BCI is prepared
			$find_string="RapBatchControlInfo";


			## 2.3.2 We need just this part of the structure for the version and release.

			$bci_asn = $asn->find($find_string) or do { $self->{error}=$asn->error; return undef };


			## 2.3.3 The fisical "header" of the file is dump into $bci_buf

			$bci_buf = $self->_get_bci($guess_file_type) || return undef;


			## 2.3.4 Decode file buffer into the ASN1 tree.

			$bci_dec = $bci_asn->decode($bci_buf);


			## 2.3.5 Ok, no more tries.

			if ( $bci_asn->error ) {


				## 
				## 2.4 If nothing works we show the error message.

				$self->{error}="File Type Unknown or Failed to get it: ".$asn->error;
				croak $self->error();

			} else {

				$self->file_type("RAP");

			}
		} else {

			$self->file_type("TAP");

		}

	} else {

		$self->file_type("TAP");

	}

	my $file_type=$self->file_type;


	## 
	## 3. According to the type of file we fill the respective version and release.
	## 
	
	if ( $file_type eq "TAP" ) {
		$self->{_version}=$bci_dec->{'specificationVersionNumber'};
		$self->{_release}=$bci_dec->{'releaseVersionNumber'};
	} else { # is RAP
		$self->{_version}=$bci_dec->{'rapSpecificationVersionNumber'};
		$self->{_release}=$bci_dec->{'rapReleaseVersionNumber'};
		$self->{_supl_version}=$bci_dec->{'specificationVersionNumber'};
		$self->{_supl_release}=$bci_dec->{'releaseVersionNumber'};
	}

}


#----------------------------------------------------------------
# Method:       _select_spec_file
# Description:  Selects the file with the ASN Specifications 
#               according to the version of the file.
#               Nomenclature specified: TAP0309.asn for the spec-
#               ifications of the TAP3r9 and RAP0102.asn for the 
#               specifications of the RAP1r2.
# Parameters:   version
#               release
#               file_type
# Returns:      filename of the Specification ASN.1
# Type:         Private
# Restrictions: N/A
#----------------------------------------------------------------
sub _select_spec_file
{
	my $self=shift;

	my $version=shift;
	my $release=shift;
	my $file_type=shift;

	$version=sprintf("%02d", $version);
	$release=sprintf("%02d", $release);

	my $spec_file;

	NEXT_CYCLE1: foreach ( @{$self->_asn_path} ) {
		$spec_file=$_."/".$file_type.$version.$release.".asn";
		if ( $spec_file ) {
			last NEXT_CYCLE1;
		}
	}

	return $spec_file || return undef;
}



#----------------------------------------------------------------
# Method:       _select_asn_struct
# Description:  Selects and prepares the ASN specification
#               to be used.
# Parameters:   N/A
# Returns:      N/A
# Type:         Private
# Restrictions: $self->version, $self->release and
#               $self->file_type should defined.
#----------------------------------------------------------------
sub _select_asn_struct
{
	my $self=shift;

	my $size;
	my $spec_buf_in;

	##
	## 1. Select the ASN.1 structure
	##

	##
	## 1.1. Main ASN.1 structure file.
	##

	if ( ! $self->spec_file ) {
		$self->spec_file($self->_select_spec_file($self->{_version}, $self->{_release}, $self->file_type)) || return undef;
	}

	##
	## 1.2. If we are working with a RAP file we need to know also the version of TAP Inside the RAP.
	##

	if ( ! $self->supl_spec_file and $self->file_type eq "RAP" ) {
		$self->supl_spec_file($self->_select_spec_file($self->{_supl_version}, $self->{_supl_release}, "TAP")) || return undef;
	}

	##
	## 2. The content of the definitions files are stored into a scalar.
	##

	## 
	## 2.1. First the definition file is opend and the content filtered and stored into $spec_buf_in
	## 

	($size) = (stat($self->spec_file))[7] or do { $self->{error}="$! reading ".$self->spec_file; return undef };
	open FILE, "<".$self->spec_file or do { $self->{error}="$! opening ".$self->spec_file; return undef };
	while (<FILE>) {
		if ( /^...Structure of a ... batch/.../END/ ) {
			if ( $_ !~ m/Structure of a Tap batch/ and $_ !~ m/END/ ) {
				$spec_buf_in=$spec_buf_in.$_;
			}
		}
	}
	close FILE;

	## 
	## 2.2. If it is a RAP file, we read as well the specification of its tap file.
	## 

	if ( $self->file_type eq "RAP" ) {
		($size) = (stat($self->supl_spec_file))[7] or do { $self->{error}="$! reading ".$self->supl_spec_file; return undef };
		open FILE, "<".$self->supl_spec_file or do { $self->{error}="$! opening ".$self->supl_spec_file; return undef };
		while (<FILE>) {
			if ( /^...Structure of a ... batch/.../END/ ) {
				if ( $_ !~ m/Structure of a Tap batch/ and $_ !~ m/END/ ) {
					$spec_buf_in=$spec_buf_in.$_;
				}
			}
		}
		close FILE;
	}

	##
	## 3. let's prepare the asn difinition.
	##

	my $asn = $self->_asn;
	$asn->prepare( $spec_buf_in ) or do { $self->{error}=$asn->error; return undef };


	##
	## 4. Initialization with DataInterChange
	##

	my $dic_asn;
	if ( $self->file_type eq "TAP" ) {
		$dic_asn = $asn->find('DataInterChange') or do { $self->{error}=$asn->error; return undef };
	} else {
		$dic_asn = $asn->find('RapDataInterChange') or do { $self->{error}=$asn->error; return undef };
	}
	$self->_dic_asn($dic_asn);

}



#----------------------------------------------------------------
# Method:       decode
# Description:  decodes the TAP/RAP file into a HASH for its
#               later editing.
# Parameters:   filename
# Returns:      N/A
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub decode {
	my $self=shift;

	my $filename=shift;
	my $buf_in;
	my $size;
	
	$self->_filename($filename);


	## 
	## 1. Get the version to decode the file.
	## 

	$self->_get_file_version || return undef;


	## 
	## 2. Selection of ASN Structure.
	## 

	$self->_select_asn_struct || return undef;


	##
	## 3. We open and read all the TAP/RAP file at once.
	##

	($size) = (stat($filename))[7] or do { $self->{error}="$! reading $filename"; return undef };
	open FILE, "<$filename" or do { $self->{error}="$! opening $filename"; return undef };
	binmode FILE;
	read FILE, $buf_in, $size;
	close FILE;


	##
	## 4. Decode file buffer into the ASN1 tree.
	##

	my $dic_decode = $self->_dic_asn->decode($buf_in) or do { $self->{error}=$self->_dic_asn->error; croak $self->error() };
	$self->_dic_decode($dic_decode);

}



#----------------------------------------------------------------
# Method:       encode
# Description:  encode the HASH structure into a new TAP/RAP file
# Parameters:   filename
# Returns:      N/A
# Type:         Public
# Restrictions: N/A
#----------------------------------------------------------------
sub encode {

	my $self = shift;

	my $filename=shift;
	$self->_filename($filename);


	##
	## 1. $dic_decode will be the decoded tree of a real tap file
	##

	my $dic_decode=$self->_dic_decode;


	## 
	## 2. Select structure according to version, release and type.
	## 

	## In the case we want just to encode, we need to select and prepare
	## the structure we want to use. E.g If we want to get a TAP3r9
	## we need to select the ASN.1 structure for the TAP3r9
	$self->_select_asn_struct || return undef;


	## 
	## 3. Encode ASN1 tree into the file.
	## 

	my $buf_out = $self->_dic_asn->encode($dic_decode) or do { $self->{error}=$self->_dic_asn->error; croak $self->error() };


	## 
	## 4. Write and close file
	## 

	open FILE_OUT, ">$filename" or do { $self->{error}="$! writing $filename"; croak $self->error() };
	print FILE_OUT $buf_out ;
	close FILE_OUT;
}

sub DESTROY {}

sub error { $_[0]->{error} }

1;
