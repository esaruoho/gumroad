import * as React from "react";

import { classNames } from "$app/utils/classNames";
import {
  CurrencyCode,
  formatMinorUnitPriceWithIntl,
  formatPriceCentsWithCurrencySymbol,
  formatPriceCentsWithoutCurrencySymbolAndComma,
} from "$app/utils/currency";
import { formatRecurrenceWithDuration, RecurrenceId } from "$app/utils/recurringPricing";

import { WithTooltip } from "$app/components/WithTooltip";

type Props = {
  url?: string;
  currencyCode: CurrencyCode;
  price: number;
  oldPrice?: number | undefined;
  recurrence?:
    | {
        id: RecurrenceId;
        duration_in_months: number | null;
      }
    | undefined;
  isPayWhatYouWant: boolean;
  isSalesLimited: boolean;
  creatorName?: string | undefined;
  tooltipPosition?: "top" | "right";
  buyerCurrency?: string | null | undefined;
  buyerLocalPriceCents?: number | null | undefined;
  buyerLocalOriginalPriceCents?: number | null | undefined;
};

export const PriceTag = ({
  url,
  currencyCode,
  oldPrice,
  price,
  recurrence,
  isPayWhatYouWant,
  isSalesLimited,
  creatorName,
  tooltipPosition = "right",
  buyerCurrency,
  buyerLocalPriceCents,
  buyerLocalOriginalPriceCents,
}: Props) => {
  const buyerLocalPrice =
    buyerCurrency && buyerLocalPriceCents != null
      ? {
          currency: buyerCurrency,
          priceCents: buyerLocalPriceCents,
          originalPriceCents: buyerLocalOriginalPriceCents,
        }
      : null;
  const displayedPrice = buyerLocalPrice?.priceCents ?? price;
  const displayedOldPrice = buyerLocalPrice ? (buyerLocalPrice.originalPriceCents ?? undefined) : oldPrice;
  const displayedCurrencyCode = buyerLocalPrice?.currency ?? currencyCode;
  const formatDisplayedPrice = (amountCents: number) =>
    buyerLocalPrice
      ? formatMinorUnitPriceWithIntl(buyerLocalPrice.currency, amountCents)
      : formatPriceCentsWithCurrencySymbol(currencyCode, amountCents, { symbolFormat: "long" });

  const recurrenceLabel = recurrence
    ? formatRecurrenceWithDuration(recurrence.id, recurrence.duration_in_months)
    : null;

  const priceTag = (
    <>
      {displayedOldPrice != null ? (
        <>
          <s>{formatDisplayedPrice(displayedOldPrice)}</s>{" "}
        </>
      ) : null}
      {formatDisplayedPrice(displayedPrice)}
      {isPayWhatYouWant ? "+" : null}
      {recurrenceLabel ? ` ${recurrenceLabel}` : null}
    </>
  );
  const borderClasses = "border-r-transparent border-[calc(0.5lh+--spacing(1))] border-l-1";

  return (
    <div itemScope itemProp="offers" itemType="https://schema.org/Offer" className="flex items-center">
      <WithTooltip position={tooltipPosition} tip={priceTag}>
        <div className="relative grid grid-flow-col border border-r-0 border-border">
          <div
            className="bg-accent px-2 py-1 text-accent-foreground"
            itemProp="price"
            content={
              buyerLocalPrice
                ? formatMinorUnitPriceWithoutCurrencySymbolAndComma(buyerLocalPrice.currency, displayedPrice)
                : formatPriceCentsWithoutCurrencySymbolAndComma(currencyCode, displayedPrice)
            }
          >
            {priceTag}
          </div>
          <div className={classNames("border-border", borderClasses)} />
          <div className={classNames("absolute top-0 right-px bottom-0 border-accent", borderClasses)} />
        </div>
      </WithTooltip>
      <link itemProp="url" href={url} />
      <div itemProp="availability" className="hidden">
        {`https://schema.org/${isSalesLimited ? "LimitedAvailability" : "InStock"}`}
      </div>
      <div itemProp="priceCurrency" className="hidden">
        {displayedCurrencyCode}
      </div>
      {creatorName ? (
        <div itemProp="seller" itemType="https://schema.org/Person" className="hidden">
          <div itemProp="name" className="hidden">
            {creatorName}
          </div>
        </div>
      ) : null}
    </div>
  );
};

const formatMinorUnitPriceWithoutCurrencySymbolAndComma = (currencyCode: string, amountMinorUnits: number): string => {
  const formatter = new Intl.NumberFormat("en-US", { style: "currency", currency: currencyCode.toUpperCase() });
  const fractionDigits = formatter.resolvedOptions().maximumFractionDigits;
  const amount = amountMinorUnits / 10 ** fractionDigits;
  return amount.toLocaleString("en-US", {
    minimumFractionDigits: amount % 1 === 0 ? 0 : fractionDigits,
    maximumFractionDigits: fractionDigits,
    useGrouping: false,
  });
};
