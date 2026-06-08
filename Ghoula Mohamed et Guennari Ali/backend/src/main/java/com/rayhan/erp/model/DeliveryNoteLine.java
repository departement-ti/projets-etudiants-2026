package com.rayhan.erp.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "delivery_note_lines")
@Getter
@Setter
@NoArgsConstructor
public class DeliveryNoteLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "delivery_note_id")
    private DeliveryNote deliveryNote;

    @ManyToOne(optional = false)
    @JoinColumn(name = "sales_order_line_id")
    private SalesOrderLine salesOrderLine;

    @ManyToOne(optional = false)
    @JoinColumn(name = "article_id")
    private Article article;

    @Column(nullable = false, precision = 15, scale = 3)
    private BigDecimal quantiteLivree;
}
