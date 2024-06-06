import { createElement } from "lwc";
import CustomerSearchFormInputs from "c/customerSearchFormInputs";

// Import constants from component
import {
  SEARCH_FORM_TITLE,
  FIRST_NAME_LABEL,
  LAST_NAME_LABEL,
  PHONE_NUMBER_LABEL,
  EMAIL_ADDRESS_LABEL,
  SEARCH_BUTTON_LABEL,
  CLEAR_BUTTON_LABEL,
} from "c/customerSearchFormInputs";

/**
 * Sets the value of the a form input element and fires the 'change' event.
 * Does not currently support all components or input types. These should be added as needed.
 *
 * @param {Element} element
 * @param {any} value - Set the input element's value to this.
 */
function changeInputFieldValue(element, value) {
  if (element?.nodeName.toLowerCase() === "lightning-input") {
    element.value = value;
    element.dispatchEvent(
      new CustomEvent("change", { detail: { value: element.value } })
    );
    return;
  }

  throw new Error(`Unhandled element: '${element?.nodeName}'`);
}

/**
 * Finds and returns input field based on the `data-field-name` attribute.
 *
 * @param {Element} element - The element to run `querySelector` on
 * @param {string} fieldName - The dataFieldName attribute to query
 * @returns {HTMLElement} - The HTMLElement that was found
 */
function getInputFieldElement(element, fieldName) {
  return element.shadowRoot.querySelector(`[data-field-name='${fieldName}']`);
}

/**
/**
 * Helper function to flush all pending promises in the event loop.
 * Useful for ensuring all asynchronous operations are complete before
 * proceeding with test assertions.
 * @returns {Promise<void>} A promise that resolves after all pending promises are flushed.
 */
function flushAllPromises() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

describe("c-customer-search-form-inputs", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    // Reset all jest mocks after each test
    jest.clearAllMocks();
  });

  it("displays component title", () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

    // Assert
    const cardCmp = element.shadowRoot.querySelector("lightning-card");
    expect(cardCmp).not.toBeNull();
    expect(cardCmp.title).toBe(SEARCH_FORM_TITLE);
  });

  it("displays search form input and button elements", () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

    // Assert
    const firstNameInput = getInputFieldElement(element, "firstName");
    expect(firstNameInput).not.toBeNull();
    expect(firstNameInput.type).toBe("text");
    expect(firstNameInput.label).toBe(FIRST_NAME_LABEL);
    expect(firstNameInput.placeholder).toBe(FIRST_NAME_LABEL);
    expect(firstNameInput.maxLength).toBe("40");
    expect(firstNameInput.value).toBe("");

    const lastNameInput = getInputFieldElement(element, "lastName");
    expect(lastNameInput).not.toBeNull();
    expect(lastNameInput.type).toBe("text");
    expect(lastNameInput.label).toBe(LAST_NAME_LABEL);
    expect(lastNameInput.placeholder).toBe(LAST_NAME_LABEL);
    expect(lastNameInput.maxLength).toBe("80");
    expect(lastNameInput.value).toBe("");

    const emailAddressInput = getInputFieldElement(element, "emailAddress");
    expect(emailAddressInput).not.toBeNull();
    expect(emailAddressInput.type).toBe("email");
    expect(emailAddressInput.label).toBe(EMAIL_ADDRESS_LABEL);
    expect(emailAddressInput.placeholder).toBe(EMAIL_ADDRESS_LABEL);
    expect(emailAddressInput.maxLength).toBe("80");
    expect(emailAddressInput.value).toBe("");

    const phoneNumberInput = getInputFieldElement(element, "phoneNumber");
    expect(phoneNumberInput).not.toBeNull();
    expect(phoneNumberInput.type).toBe("tel");
    expect(phoneNumberInput.label).toBe(PHONE_NUMBER_LABEL);
    expect(phoneNumberInput.placeholder).toBe(PHONE_NUMBER_LABEL);
    expect(phoneNumberInput.maxLength).toBe("40");
    expect(phoneNumberInput.value).toBe("");

    const buttons = [
      ...element.shadowRoot.querySelectorAll("lightning-button"),
    ];
    expect(buttons.length).toBe(2);

    const searchButton = buttons[0];
    expect(searchButton).not.toBeNull();
    expect(searchButton.label).toBe(SEARCH_BUTTON_LABEL);

    const clearButton = buttons[1];
    expect(clearButton).not.toBeNull();
    expect(clearButton.label).toBe(CLEAR_BUTTON_LABEL);
  });

  it("trims whitespace on input 'blur' event", async () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

	// Update the 'firstName' field and fire the `change` event
    const firstNameInput = getInputFieldElement(element, "firstName");
    changeInputFieldValue(firstNameInput, "Joan ");

	// Fire the `blur` event on the 'firstName' field
    firstNameInput.dispatchEvent(new CustomEvent("blur"));

    // Wait for any asynchronous code to complete
    await flushAllPromises();

    // Assert
    expect(firstNameInput.value).toBe("Joan");
  });

  it("fires the 'inputchange' event when input field changed", async () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

	// Add event handler for the `inputchange` event
    const inputChangeEvent = jest.fn();
    element.addEventListener("inputchange", inputChangeEvent);

    // Update the first name field and fire the 'change' event
    const firstNameInput = getInputFieldElement(element, "firstName");
    changeInputFieldValue(firstNameInput, "Joan");

    // Wait for any asynchronous code to complete
    await flushAllPromises();

    // Assert
    expect(inputChangeEvent).toHaveBeenCalled();
    expect(inputChangeEvent.mock.calls[0][0].detail.fieldName).toEqual(
      "firstName"
    );
    expect(inputChangeEvent.mock.calls[0][0].detail.value).toEqual("Joan");
  });

  it("allows pre-populating input field values", () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });
    element.firstName = "Joan";
    element.lastName = "Watson";
    element.emailAddress = "jwatson@example.com";
    element.phoneNumber = "0401234567";

    // Act
    document.body.appendChild(element);

    // Assert
    const firstNameInput = getInputFieldElement(element, "firstName");
    expect(firstNameInput).not.toBeNull();
    expect(firstNameInput.value).toBe("Joan");

    const lastNameInput = getInputFieldElement(element, "lastName");
    expect(lastNameInput).not.toBeNull();
    expect(lastNameInput.value).toBe("Watson");

    const emailAddressInput = getInputFieldElement(element, "emailAddress");
    expect(emailAddressInput).not.toBeNull();
    expect(emailAddressInput.value).toBe("jwatson@example.com");

    const phoneNumberInput = getInputFieldElement(element, "phoneNumber");
    expect(phoneNumberInput).not.toBeNull();
    expect(phoneNumberInput.value).toBe("0401234567");
  });
});
