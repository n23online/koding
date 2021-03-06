package j_account

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/runtime"
	"github.com/go-openapi/swag"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// JAccountFetchRoleReader is a Reader for the JAccountFetchRole structure.
type JAccountFetchRoleReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *JAccountFetchRoleReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewJAccountFetchRoleOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewJAccountFetchRoleOK creates a JAccountFetchRoleOK with default headers values
func NewJAccountFetchRoleOK() *JAccountFetchRoleOK {
	return &JAccountFetchRoleOK{}
}

/*JAccountFetchRoleOK handles this case with default header values.

OK
*/
type JAccountFetchRoleOK struct {
	Payload JAccountFetchRoleOKBody
}

func (o *JAccountFetchRoleOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JAccount.fetchRole/{id}][%d] jAccountFetchRoleOK  %+v", 200, o.Payload)
}

func (o *JAccountFetchRoleOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	// response payload
	if err := consumer.Consume(response.Body(), &o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

/*JAccountFetchRoleOKBody j account fetch role o k body
swagger:model JAccountFetchRoleOKBody
*/
type JAccountFetchRoleOKBody struct {
	models.JAccount

	models.DefaultResponse
}

// UnmarshalJSON unmarshals this object from a JSON structure
func (o *JAccountFetchRoleOKBody) UnmarshalJSON(raw []byte) error {

	var jAccountFetchRoleOKBodyAO0 models.JAccount
	if err := swag.ReadJSON(raw, &jAccountFetchRoleOKBodyAO0); err != nil {
		return err
	}
	o.JAccount = jAccountFetchRoleOKBodyAO0

	var jAccountFetchRoleOKBodyAO1 models.DefaultResponse
	if err := swag.ReadJSON(raw, &jAccountFetchRoleOKBodyAO1); err != nil {
		return err
	}
	o.DefaultResponse = jAccountFetchRoleOKBodyAO1

	return nil
}

// MarshalJSON marshals this object to a JSON structure
func (o JAccountFetchRoleOKBody) MarshalJSON() ([]byte, error) {
	var _parts [][]byte

	jAccountFetchRoleOKBodyAO0, err := swag.WriteJSON(o.JAccount)
	if err != nil {
		return nil, err
	}
	_parts = append(_parts, jAccountFetchRoleOKBodyAO0)

	jAccountFetchRoleOKBodyAO1, err := swag.WriteJSON(o.DefaultResponse)
	if err != nil {
		return nil, err
	}
	_parts = append(_parts, jAccountFetchRoleOKBodyAO1)

	return swag.ConcatJSON(_parts...), nil
}

// Validate validates this j account fetch role o k body
func (o *JAccountFetchRoleOKBody) Validate(formats strfmt.Registry) error {
	var res []error

	if err := o.JAccount.Validate(formats); err != nil {
		res = append(res, err)
	}

	if err := o.DefaultResponse.Validate(formats); err != nil {
		res = append(res, err)
	}

	if len(res) > 0 {
		return errors.CompositeValidationError(res...)
	}
	return nil
}
